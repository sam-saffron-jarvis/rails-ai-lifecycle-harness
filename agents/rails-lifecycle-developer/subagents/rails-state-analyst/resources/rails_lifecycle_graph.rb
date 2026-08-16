#!/usr/bin/env ruby
# frozen_string_literal: true

# Deterministically inventory Rails lifecycle declarations in the current repository.
# Static application-source scanner only: no Rails boot, dependency source,
# evaluator data, or task metadata.

require "digest"
require "json"
require "pathname"

ROOT = Pathname.pwd.realpath
SCAN_ROOTS = %w[app/models app/jobs app/controllers lib/rails_ext].freeze
OPTIONAL_ROOTS = %w[db/migrate].freeze
OPTIONAL_FILES = %w[db/schema.rb].freeze
DECLARATIONS = %w[
  has_many_attached has_one_attached has_many has_one belongs_to delegated_type has_markdown
].freeze
CALLBACKS = %w[
  before_destroy around_destroy after_destroy after_destroy_commit before_commit after_commit
  after_create_commit after_update_commit after_save_commit after_rollback after_update after_save before_save
].freeze

def relative(path)
  path.relative_path_from(ROOT).to_s
end

def files_to_scan
  files = []
  (SCAN_ROOTS + OPTIONAL_ROOTS).each do |root|
    path = ROOT.join(root)
    files.concat(path.glob("**/*.rb").select(&:file?)) if path.directory?
  end
  OPTIONAL_FILES.each do |name|
    path = ROOT.join(name)
    files << path if path.file?
  end
  files.uniq.sort_by { |path| relative(path) }
end

def source_digest(paths)
  digest = Digest::SHA256.new
  paths.each do |path|
    name = relative(path).b
    data = path.binread
    digest << [name.bytesize].pack("Q>") << name
    digest << [data.bytesize].pack("Q>") << data
  end
  digest.hexdigest
end

def symbol_at(lines, index)
  stack = []
  lines.first(index + 1).each do |line|
    code = line.split("#", 2).first.to_s
    match = code.match(/^(\s*)(?:class|module)\s+([A-Z][A-Za-z0-9_:]*)/)
    next unless match

    indent = match[1].gsub("\t", "  ").length
    name = match[2]
    stack.select! { |entry| entry[0] < indent }
    if name.include?("::")
      stack = [[indent, name]]
    else
      stack << [indent, name]
    end
  end
  stack.empty? ? "(top-level)" : stack.map(&:last).join("::")
end

def statement(lines, index)
  parts = [lines[index].strip]
  balance = parts[0].count("(") - parts[0].count(")") + parts[0].count("{") - parts[0].count("}")
  cursor = index
  while cursor + 1 < lines.length && cursor - index < 12 && (balance.positive? || parts.last.rstrip.end_with?(","))
    cursor += 1
    part = lines[cursor].strip
    parts << part
    balance += part.count("(") - part.count(")") + part.count("{") - part.count("}")
  end
  parts.join(" ")
end

def token_option(source, key)
  match = source.match(/\b#{Regexp.escape(key)}:\s*(?::([A-Za-z_][A-Za-z0-9_!?]*)|["']([^"']+)["'])/)
  match && (match[1] || match[2])
end

def target_name(source, macro)
  tail = source[(source.index(macro) + macro.length)..]
  match = tail.match(/\(?\s*(?::([A-Za-z_][A-Za-z0-9_!?]*)|["']([^"']+)["'])/)
  match ? (match[1] || match[2]) : "(dynamic)"
end

def dependent_semantics(macro, dependent)
  mode = dependent || "default/unspecified"
  if %w[has_one_attached has_many_attached].include?(macro)
    if dependent.nil? || dependent == "purge_later"
      return [
        dependent || "purge_later (Rails default)",
        "destroy attachment rows; attachment after_destroy_commit schedules blob purge",
        "yes (attachment destroy)",
        "blob row + stored file purged asynchronously after commit"
      ]
    end
    if dependent == "destroy"
      return [mode, "destroy attachment rows only", "yes (attachment destroy)",
              "attachment removed; blob row + stored file are not purged by dependent callback"]
    end
    return [mode, "attachment association dependent=#{dependent}", "depends on Rails mode",
            "inspect attachment reflection and blob ownership"]
  end

  case dependent
  when "destroy"
    [mode, "instantiate and destroy associated records", "yes", "n/a"]
  when "destroy_async"
    [mode, "enqueue associated-record destruction after owner commit", "yes, in async destroy", "n/a"]
  when "delete", "delete_all"
    [mode, "direct SQL deletion of associated records", "no", "n/a"]
  when "nullify"
    [mode, "direct foreign-key nullification", "no", "n/a"]
  else
    [mode, "Rails association default/declared behavior", "not guaranteed", "n/a"]
  end
end

def fact(path:, line:, symbol:, kind:, association:, dependent:, mechanism:, callbacks:, attachment:, declaration:)
  {
    source_symbol: symbol,
    file: relative(path),
    line: line,
    kind: kind,
    owns_or_association: association,
    dependent_mode: dependent,
    deletion_mechanism: mechanism,
    callbacks_expected: callbacks,
    attachment_lifecycle: attachment,
    declaration: declaration.strip.gsub(/\s+/, " ")[0, 500]
  }
end

def scan_file(path)
  lines = path.read(encoding: "UTF-8", invalid: :replace, undef: :replace).lines(chomp: true)
  rows = []

  lines.each_with_index do |line, index|
    code = line.split("#", 2).first.to_s
    symbol = symbol_at(lines, index)
    source = statement(lines, index)

    if (match = code.match(/^\s*(#{DECLARATIONS.join("|")})\b/))
      macro = match[1]
      name = target_name(source, macro)
      dependent = token_option(source, "dependent")
      mode, mechanism, callbacks, attachment = dependent_semantics(macro, dependent)
      flags = []
      flags << "polymorphic" if source.match?(/\bpolymorphic:\s*true/)
      flags << "polymorphic-as:#{token_option(source, "as")}" if token_option(source, "as")
      flags << "through:#{token_option(source, "through")}" if token_option(source, "through")
      association = "#{macro} #{name}"
      association += " [#{flags.join(", ")}]" unless flags.empty?
      rows << fact(path: path, line: index + 1, symbol: symbol, kind: "declaration",
                   association: association, dependent: mode, mechanism: mechanism,
                   callbacks: callbacks, attachment: attachment, declaration: source)
    end

    if (match = code.match(/^\s*(#{CALLBACKS.join("|")})\b/))
      callback = match[1]
      event = if callback.include?("commit")
                "after outer transaction commit"
              elsif callback.include?("rollback")
                "after transaction rollback"
              else
                "record lifecycle"
              end
      rows << fact(path: path, line: index + 1, symbol: symbol, kind: "callback",
                   association: callback, dependent: "n/a", mechanism: event,
                   callbacks: "yes when lifecycle reaches callback; direct delete/delete_all bypass callbacks",
                   attachment: "callback body may enqueue/purge; inspect declaration", declaration: source)
    end

    code.scan(/(?<receiver>[A-Za-z_@][A-Za-z0-9_@.:()!?]*(?:\.[A-Za-z_][A-Za-z0-9_!?]*(?:\([^)]*\))?)*)\.(?<operation>destroy!|destroy|destroy_all|delete_all|delete)\b/) do
      match = Regexp.last_match
      receiver = match[:receiver]
      operation = match[:operation]
      next if operation == "delete" && receiver.match?(/params|cookies|session|options|attributes/)

      callbacks = operation.start_with?("destroy") ? "yes" : "no"
      mechanism = if operation == "destroy_all"
                    "instantiate/destroy each record"
                  elsif operation.start_with?("destroy")
                    "record destroy"
                  else
                    "direct SQL/record deletion"
                  end
      rows << fact(path: path, line: index + 1, symbol: symbol, kind: "deletion_call",
                   association: "#{receiver}.#{operation}", dependent: "call-site", mechanism: mechanism,
                   callbacks: callbacks,
                   attachment: "follow downstream attachment callbacks only when destroy callbacks run",
                   declaration: code)
    end

    code.scan(/(?<job>[A-Z][A-Za-z0-9_:]*Job)(?:\.set\([^)]*\))?\.perform_later\b/) do
      job = Regexp.last_match[:job]
      rows << fact(path: path, line: index + 1, symbol: symbol, kind: "job_enqueue",
                   association: job, dependent: "job class/config dependent", mechanism: "perform_later",
                   callbacks: "n/a", attachment: "enqueue timing depends on transaction-commit policy",
                   declaration: code)
    end

    if code.match?(/\b(?:transaction|with_transaction_returning_status)\s+do\b/)
      rows << fact(path: path, line: index + 1, symbol: symbol, kind: "transaction",
                   association: "transaction block", dependent: "n/a",
                   mechanism: "outer commit controls registered after_commit work",
                   callbacks: "after_commit only on commit; after_rollback only on rollback",
                   attachment: "jobs/purges may be deferred or dropped according to policy", declaration: code)
    end

    if (match = code.match(/\bt\.(?:references|belongs_to)\s+[:"']([A-Za-z_][A-Za-z0-9_]*)["']?.*\bpolymorphic:\s*true/))
      rows << fact(path: path, line: index + 1, symbol: symbol, kind: "schema_edge",
                   association: match[1], dependent: "database reference",
                   mechanism: "type + id polymorphic reference", callbacks: "n/a",
                   attachment: "historical class names live in the type column", declaration: code)
    end
  end

  rows
end

if %w[verification_test.rb solution.patch].any? { |name| ROOT.join(name).exist? }
  warn "refusing evaluator/task directory as repository root"
  exit 2
end

paths = files_to_scan
abort "no Rails application source found in allowed roots" if paths.empty?
rows = paths.flat_map { |path| scan_file(path) }
rows.sort_by! { |row| [row[:file], row[:line], row[:kind], row[:owns_or_association]] }

packet = {
  schema_version: "rails_lifecycle_graph/v1",
  scan_policy: {
    repository_root: ".",
    included_roots: SCAN_ROOTS,
    optional_roots: OPTIONAL_ROOTS,
    optional_files: OPTIONAL_FILES,
    excluded: %w[test spec vendor gems evaluator task_metadata solution_artifacts]
  },
  source_manifest_sha256: source_digest(paths),
  source_file_count: paths.length,
  row_count: rows.length,
  rows: rows,
  required_solver_evidence_schema: {
    direct_edges: [{ owner: "string", resource: "string", destroy_path: "string", callbacks: "yes|no|conditional", evidence: "file:line" }],
    indirect_edges: [{ from: "string", via: "string", to: "string", evidence: "file:line" }],
    historical_edges: [{ current_owner: "string", historical_owner: "string", destroy_path: "string", evidence: "file:line" }],
    transaction_boundaries: [{ operation: "string", commit_behavior: "string", rollback_behavior: "string", evidence: "file:line" }],
    focused_existing_test: { path: "string", command: "string" },
    minimal_patch_plan: [{ file: "string", fact_addressed: "string" }]
  }
}

puts JSON.pretty_generate(packet)
