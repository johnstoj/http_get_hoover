#!/usr/bin/env ruby

require 'rubygems'
require 'packetfu'
require 'resolv'
require 'colorize'

class HttpGetHoover
	def initialize interface
		@interface = interface
	end

	def host_from_ip ip_address
		begin
			Resolv.new.getname ip_address
		rescue Resolv::ResolvError
			ip_address
		end
	end

	def start filter = "(dst port 80 or dst port 8080) and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420"	# 0x47455420 = 'GET '
		packets = PacketFu::Capture.new :iface => @interface, :start => true, :promisc => true, :filter => filter
		
		# Packet streaming blocks... Start it in a thread...
		@capture_thread = Thread.new do
			packets.stream.each do |packet|
				packet = PacketFu::Packet.parse packet
				puts "#{Time.now}: #{host_from_ip packet.ip_saddr}:#{packet.tcp_src} -> #{host_from_ip packet.ip_daddr}:#{packet.tcp_dst}".yellow
				packet.payload.split("\r\n").each do |line|
					color = :red if line.match("^Cookie")
					puts line.colorize(color)
				end
				puts "\r\n"
			end
		end

		begin
			oldstty=`stty -g`
			system "stty -icanon min 1 time 0 -isig -echo"	# Non-portable h4x.  :(

			loop do
				case STDIN.getc
					when "\e" then 							# ESC to exit.
						Thread.kill(@capture_thread)		# No choice but to force kill.  :(
						break
				end
			end
		ensure
			system "stty #{oldstty}"
		end
	end
end


interface = ARGV[0].nil? ? 'en0' : ARGV[0]
puts "Hoovering HTTP GET requests on '#{interface}'... 'ESC' to stop.".light_blue
HttpGetHoover.new(interface).start
puts "Done!".light_blue
