require_relative "../selector"

module Hokusai::Automation
  module Converters
    module SelectorConverter
      def self.parse_selectors(selector)
        final = []
        scanner = StringScanner.new(selector)

        while !scanner.eos?
          if node = scan_node(scanner)
            id = scan_id(scanner)
            classes = scan_classes(scanner)
            final << Selector.new(node, id, classes)

            scan_space(scanner)
          elsif id = scan_id(scanner)
            classes = scan_classes(scanner)
            final << Selector.new(nil, id, classes)

            scan_space(scanner)
          elsif classes = scan_classes(scanner)
            final << Selector.new(nil, nil, classes)

            scan_space(scanner)
          else
            scanner.terminate

            if scanner.rest.empty?
              scanner.terminate
            else
              raise Automation::Error.new("Error Scanning: Improperly formatted selector: #{scanner.rest}")
            end
          end
        end

        final
      end

      private

      def self.scan_id(scanner)
        scanner.scan(/\#([A-Za-z0-9-_]+)/)
        scanner[1]
      end

      def self.scan_classes(scanner)
        scanner.scan(/((\.[A-Za-z0-9-_]+)+)/)
        scanner[1]&.[](1..-1)&.split(".")
      end

      def self.scan_node(scanner)
        scanner.scan(/[A-Za-z0-9-_]+/)
      end

      def self.scan_space(scanner)
        scanner.scan(/\s*/)
      end
    end
  end
end