require "tmpdir"

require "hbc/container/base"

module Hbc
  class Container
    class Gpg < Base
      def self.me?(criteria)
        criteria.extension(/GPG/n)
      end

      def import_key
        if @cask.gpg.nil?
          raise CaskError, "Expected to find gpg public key in formula. Cask '#{@cask}' must add: key_id or key_url"
        end

        args = if @cask.gpg.key_id
          ["--recv-keys", @cask.gpg.key_id]
        elsif @cask.gpg.key_url
          ["--fetch-key", @cask.gpg.key_url.to_s]
        end

        @command.run!("gpg", args: args)
      end

      def extract
        if (gpg = which("gpg")).nil?
          raise CaskError, "Expected to find gpg executable. Cask '#{@cask}' must add: depends_on formula: 'gpg'"
        end

        import_key

        Dir.mktmpdir do |unpack_dir|
          @command.run!(gpg, args: ["--batch", "--yes", "--output", Pathname(unpack_dir).join(File.basename(@path.basename)), "--decrypt", @path])

          extract_nested_inside(unpack_dir)
        end
      end
    end
  end
end
