#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

agent_dir = ENV.fetch("TERM_LLM_AGENT_DIR")
input = begin
  raw = $stdin.read
  raw.empty? ? {} : JSON.parse(raw)
rescue JSON::ParserError
  {}
end
focus = input.fetch("focus", "").to_s
scanner = File.join(agent_dir, "resources", "rails_lifecycle_graph.rb")
stdout, stderr, status = Open3.capture3("ruby", scanner, chdir: Dir.pwd)
abort(stderr.empty? ? "lifecycle scanner failed" : stderr) unless status.success?
packet = JSON.parse(stdout)
rows = packet.fetch("rows")

tokens = focus.downcase.scan(/[a-z][a-z0-9_]{3,}/).uniq
high_risk = lambda do |row|
  %w[delete delete_all destroy destroy_async purge purge_later].include?(row["dependent_mode"]) ||
    %w[callback deletion_call job_enqueue transaction].include?(row["kind"]) ||
    row["owns_or_association"].include?("attached") ||
    row["callbacks_expected"] == "no"
end
score = lambda do |row|
  text = row.values.join(" ").downcase
  tokens.sum { |token| text.include?(token) ? 4 : 0 } + (high_risk.call(row) ? 2 : 0)
end
selected = rows.select { |row| high_risk.call(row) || score.call(row).positive? }
selected = selected.sort_by { |row| [-score.call(row), row["file"], row["line"]] }.first(32)

puts File.read(File.join(agent_dir, "resources", "rails-lifecycle-tool-reference.md"))
puts
puts "## Current repository facts"
puts
puts "Focus: #{focus.empty? ? '(none supplied)' : focus}"
puts "Scanned #{packet.fetch("source_file_count")} files; showing #{selected.length} of #{packet.fetch("row_count")} lifecycle rows."
puts
puts "| Evidence | Symbol | Kind | Association/call | Dependent | Callbacks | Mechanism |"
puts "|---|---|---|---|---|---|---|"
selected.each do |row|
  cells = [
    "#{row["file"]}:#{row["line"]}", row["source_symbol"], row["kind"],
    row["owns_or_association"], row["dependent_mode"], row["callbacks_expected"],
    row["deletion_mechanism"]
  ].map { |value| value.to_s.gsub("|", "\\|").gsub(/\s+/, " ") }
  puts "| #{cells.join(' | ')} |"
end
puts
puts "## Required evidence before editing"
puts
puts "- Map every explicit user requirement to its persisted/rendered code path and focused evidence."
puts "- Account for direct, indirect, and historical ownership edges."
puts "- Identify callback reachability for every relevant deletion path."
puts "- Identify commit/rollback behavior for jobs or external work."
puts "- Do not invent a method without finding its consumer."
puts "- Use grep/read_file for any relevant source omitted from this compact static report."
