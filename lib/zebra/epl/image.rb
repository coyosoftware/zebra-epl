require "zebra/epl/printable"
require 'rmagick'

require 'byebug'
module Zebra
  module Epl
    class Image
      include Printable

      def to_epl
        check_attributes
        ["GW#{x}", y, image_width, image_length, image_data].join(",")
      end

      private

      def image
        @image ||= Magick::Image.read(data)[0]
      end

      def image_width
        (image.columns / 8.0).ceil
      end

      def image_length
        image.rows
      end

      def image_data
        dots = Array.new(image.columns * image.rows)

        index = 0
        (0..image.rows).each do |y|
          (0..image.columns).each do |x|
            pixel = image.pixel_color(x, y)

            luma = (((pixel.red / 256) * 0.3) + ((pixel.green / 256) * 0.59) + ((pixel.blue / 256) * 0.11)).to_i

            dots[index] = luma < 127
            index += 1
          end
        end

        packed_data = []

        (0..image.rows).each do |y|
          (0..(image_width * 8)).each do
            s = 0
            x = 0

            (0..7).each do |b|
              v = false

              if (x < image.columns)
                i = (y * image.columns) + x
                v = dots[i]
              end

              s = (v ? 0 : 1) << (7 - b)

              x += 1
            end

            packed_data << s
          end
        end

        packed_data.pack('c*')
      end

      def check_attributes
        super
        raise MissingAttributeError.new("the data to be printed is not a file") unless File.file?(data)
        raise MissingAttributeError.new("the data to be printed is not a PCX image") if File.extname(data).downcase != '.pcx'
      end
    end
  end
end
