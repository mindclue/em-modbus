# Copyright © 2016 Andy Rohr <andy.rohr@mindclue.ch>
# All rights reserved.


module Modbus

  class PDU

    # Base class PDU for modbus bit based functions (request message)
    #
    class ReadBitsRequest < PDU
      VALID_BIT_COUNTS = 1 .. 2000


      attr_accessor :start_addr, :bit_count


      # Initializes a new PDU instance. Decodes from protocol data if given.
      #
      # @param data [Modbus::ProtocolData] The protocol data to decode.
      #
      def initialize(data = nil, func_code = nil)
        @start_addr = 0
        @bit_count  = 0
        super
      end


      # Decodes a PDU from protocol data.
      #
      # @param data [Modbus::ProtocolData] The protocol data to decode.
      #
      def decode(data)
        @start_addr = data.shift_word
        @bit_count  = data.shift_word
      end


      # Encodes a PDU into protocol data.
      #
      # @return [Modbus::ProtocolData] The protocol data representation of this object.
      #
      def encode
        data = super
        data.push_word @start_addr
        data.push_word @bit_count
        data
      end


      # Returns the length of the PDU in bytes.
      #
      # @return [Integer] The length.
      #
      def length
        5
      end


      # Validates the PDU. Raises exceptions if validation fails.
      #
      def validate
        unless VALID_BIT_COUNTS.include?(@bit_count)
          fail ClientError, "Bit count must be in (1..2000), got #{@bit_count.inspect}"
        end
      end

    end


    # Base class PDU for modbus bit based functions (response message)
    #
    class ReadBitsResponse < PDU
      attr_accessor :bit_values


      # Initializes a new PDU instance. Decodes from protocol data if given.
      #
      # @param data [Modbus::ProtocolData] The protocol data to decode.
      #
      def initialize(data = nil, func_code = nil)
        @bit_values = []
        super
      end


      # Decodes a PDU from protocol data.
      #
      # @param data [Modbus::ProtocolData] The protocol data to decode.
      #
      def decode(data)
        byte_count = data.shift_byte
        byte_count.times do
          byte = data.shift_byte

          8.times do |bit|
            @bit_values.push byte[bit] == 1
          end
        end
      end


      # Encodes a PDU into protocol data.
      #
      # @return [Modbus::ProtocolData] The protocol data representation of this object.
      #
      def encode
        data = super
        data.push_byte byte_count

        @bit_values.each_slice(8) do |bools|
          value   = 0
          bit_pos = 0

          bools.each do |bool|
            value   += (1 << bit_pos) if bool
            bit_pos += 1
          end

          data.push_byte value
        end
        data
      end


      # Returns the length of the register values in bytes.
      #
      # @return [Integer] The length.
      #
      def byte_count
        (@bit_values.size.to_f / 8).ceil
      end


      # Returns the length of the PDU in bytes.
      #
      # @return [Integer] The length.
      #
      def length
        # +1 for func_code, +1 for byte_count
        byte_count + 2
      end


      # Validates the PDU. Raises exceptions if validation fails.
      #
      def validate

      end

    end

  end

end # Modbus


