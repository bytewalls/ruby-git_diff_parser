module GitDiffParser
  # Parsed patch
  class Patch
    RANGE_INFORMATION_LINE = /^@@ -(?<old_line_number>\d+),.+\+(?<line_number>\d+),/
    MODIFIED_LINE = /^\+(?!\+|\+)/
    REMOVED_LINE = /^[-]/
    NOT_REMOVED_LINE = /^[^-]/

    attr_accessor :file, :body, :secure_hash
    # @!attribute [rw] file
    #   @return [String, nil] file path or nil
    # @!attribute [rw] body
    #   @return [String, nil] patch section in `git diff` or nil
    #   @see #initialize
    # @!attribute [rw] secure_hash
    #   @return [String, nil] target sha1 hash or nil

    # @param body [String] patch section in `git diff`.
    #   GitHub's pull request file's patch.
    #   GitHub's commit file's patch.
    #
    #    <<-BODY
    #    @@ -11,7 +11,7 @@ def valid?
    #
    #       def run
    #         api.create_pending_status(*api_params, 'Hound is working...')
    #    -    @style_guide.check(pull_request_additions)
    #    +    @style_guide.check(api.pull_request_files(@pull_request))
    #         build = repo.builds.create!(violations: @style_guide.violations)
    #         update_api_status(build)
    #       end
    #    @@ -19,6 +19,7 @@ def run
    #       private
    #
    #       def update_api_status(build = nil)
    #    +    # might not need this after using Rubocop and fetching individual files.
    #         sleep 1
    #         if @style_guide.violations.any?
    #           api.create_failure_status(*api_params, 'Hound does not approve', build_url(build))
    #    BODY
    #
    # @param options [Hash] options
    # @option options [String] :file file path
    # @option options [String] 'file' file path
    # @option options [String] :secure_hash target sha1 hash
    # @option options [String] 'secure_hash' target sha1 hash
    #
    # @see https://developer.github.com/v3/repos/commits/#get-a-single-commit
    # @see https://developer.github.com/v3/pulls/#list-pull-requests-files
    def initialize(body, options = {})
      @body = body || ''
      @file = options[:file] || options['file'] if options[:file] || options['file']
      @secure_hash = options[:secure_hash] || options['secure_hash'] if options[:secure_hash] || options['secure_hash']
    end

    # @return [Array<Line>] changed lines
    def changed_lines
      line_number = 0

      lines.each_with_index.inject([]) do |lines, (content, patch_position)|
        case content
        when RANGE_INFORMATION_LINE
          line_number = Regexp.last_match[:line_number].to_i
        when MODIFIED_LINE
          line = Line.new(
            content: content,
            number: line_number,
            patch_position: patch_position
          )
          lines << line
          line_number += 1
        when NOT_REMOVED_LINE
          line_number += 1
        end

        lines
      end
    end

    # @return [Array<Line>] removed lines
    def removed_lines
      line_number = 0

      lines.each_with_index.inject([]) do |lines, (content, patch_position)|
        case content
        when RANGE_INFORMATION_LINE
          line_number = Regexp.last_match[:old_line_number].to_i
        when REMOVED_LINE
          line = Line.new(
            content: content,
            number: line_number,
            patch_position: patch_position
          )
          lines << line
          line_number += 1
        when NOT_REMOVED_LINE
          line_number += 1
        end

        lines
      end
    end

    # @return [Array<Integer>] changed line numbers
    def changed_line_numbers
      return @changed_line_numbers if defined? @changed_line_numbers
      @changed_line_numbers ||= changed_lines.map(&:number)
    end

    # @return [Array<Integer>] removed line numbers
    def removed_line_numbers
      return @removed_line_numbers if defined? @removed_line_numbers
      @removed_line_numbers ||= removed_lines.map(&:number)
    end

    # @param line_number [Integer] line number
    #
    # @return [Integer, nil] patch position
    def find_patch_position_by_line_number(line_number)
      target = changed_lines.find { |line| line.number == line_number }
      return nil unless target
      target.patch_position
    end

    # @param line_number [Integer] line number
    #
    # @return [Integer] previous file line number
    def find_previous_position_by_line_number(line_number)
      return nil if changed_line_numbers.include?(line_number)

      added_lines_before = changed_line_numbers.count { |x| x < line_number }
      removed_lines_before = removed_lines_position_in_new.count { |x| x < line_number }

      line_number - added_lines_before + removed_lines_before
    end

    # @return [Array<Integer>] lines where deleted lines would be inserted in new file
    def removed_lines_position_in_new
      added_lines_before = ->(line){ changed_line_numbers.count { |x| x < line } }
      removed_lines_before = ->(line){ removed_line_numbers.count { |x| x < line} }

      @removed_line_position_in_new ||= begin
        array = []
        removed_line_numbers.each do |x|
          removed_before_x = removed_lines_before[x]
          array.push x + added_lines_before[x - removed_before_x] - removed_before_x
        end

        array
      end
    end

    private

    def lines
      @body.lines
    end
  end
end
