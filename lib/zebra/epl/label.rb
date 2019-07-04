# encoding: utf-8

module Zebra
  module Epl
    class Label
      class InvalidPrintSpeedError     < StandardError; end
      class InvalidPrintDensityError   < StandardError; end
      class PrintSpeedNotInformedError < StandardError; end
      class PrintMethodNotInformedError < StandardError; end

      attr_writer :copies
      attr_reader :elements, :tempfile
      attr_accessor :width, :length, :gap, :print_speed, :print_density, :print_method

      def initialize(options = {})
        options.each_pair { |key, value| self.__send__("#{key}=", value) if self.respond_to?("#{key}=") }
        @elements = []
      end

      def length_and_gap=(length_and_gap)
        self.length = length_and_gap[0]
        self.gap    = length_and_gap[1]
      end

      def print_speed=(s)
        raise InvalidPrintSpeedError unless (0..6).include?(s)
        @print_speed = s
      end

      def print_density=(d)
        raise InvalidPrintDensityError unless (0..15).include?(d)
        @print_density = d
      end

      def print_method=(m)
        if m == "direct_thermal"
          @print_method = "OD"
        elsif m == "thermal_transfer"
          @print_method = "Od"
        else
          @print_method = "O"
        end
      end

      def copies
        @copies || 1
      end

      def <<(element)
        elements << element
      end

      def dump_contents(io = STDOUT)
        check_required_configurations
        # Start options
        io << "#{print_method}\r\n"
        # Q<label height in dots>,<space between labels in dots>
        io << "Q#{length},#{gap}\r\n" if length && gap
        # q<label width in dots>
        io << "q#{width}\r\n" if width
        # Print Speed (S command)
        io << "S#{print_speed}\r\n"
        # Density (D command)
        io << "D#{print_density}\r\n" if print_density
        # ZT = Printing from top of image buffer.

        io << "\r\n"
        # Start new label
        io << "N\r\n"

        elements.each do |element|
          io << element.to_epl.force_encoding("utf-8") << "\r\n"
        end

        io << "P#{copies}\r\n\r\n"
      end

      def persist
        tempfile = Tempfile.new "zebra_label"
        dump_contents tempfile
        tempfile.close
        @tempfile = tempfile
        tempfile
      end

      def persisted?
        !!self.tempfile
      end

      private

      def check_required_configurations
        raise PrintSpeedNotInformedError unless print_speed
        raise PrintMethodNotInformedError unless print_method
      end
    end
  end
end
