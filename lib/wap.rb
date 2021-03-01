# frozen_string_literal: true
#
# WAP - give your guests WiFi Access, Printed
# Copyright (C) 2021 Georg Gadinger <nilsding@nilsding.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

require 'socket'

require 'amazing_print'
require 'securerandom'

require 'wap/repository/unifi'

require 'chunky_png'
# require 'mini_magick'
escpos_image_path = $LOAD_PATH.find { |p| p =~ /escpos-image/ }
$LOAD_PATH.delete(escpos_image_path)
require 'escpos'
$LOAD_PATH.insert($LOAD_PATH.index {|p| p =~ /escpos/}, escpos_image_path)
require 'escpos/image'

module WAP
  THAT_FOX = Escpos::Image.new(
    Config::HEADER_IMAGE,
    processor: 'ChunkyPng',
    # processor: 'MiniMagick',
    # dither: true,
    extent: true
  )

  module_function

  def run(argv = [])
    if argv.shift == 'fake'
      puts 'using fake strategy'
      Repository::Unifi.strategy Repository::Unifi::Strategy::Fake
    end

    case Config::PRINTER_CONNECT_USING.to_sym
    when :usb
      @printer = File.open(Config::PRINTER_USB, 'a+b')
    when :tcp
      @printer = TCPSocket.open(Config::PRINTER_HOST, Config::PRINTER_PORT)
    else
      abort "PRINTER_CONNECT_USING needs to be either :usb or :tcp"
    end
    @printer.sync = true
    @printer << Escpos.sequence(Escpos::HW_INIT)

    # init cleanup loop
    @last_check = 0

    loop do
      wait_for_button_push do
        clean_up_old_users
      end

      puts "PRINT #{Time.now}"
      create_and_print_user

      wait_for_button_release
    end

    @printer.close
  end

  def wait_for_button_push
    pushed = read_status == 0x1e
    until pushed
      yield if block_given?
      pushed = read_status == 0x1e
    end
  end

  def wait_for_button_release
    pushed = read_status == 0x1e
    while pushed
      yield if block_given?
      pushed = read_status == 0x1e
    end
  end

  def clean_up_old_users
    return if @last_check + Config::CLEANUP_INTERVAL > Time.now.to_i

    @last_check = Time.now.to_i

    puts "#{Time.now} checking for cleanup ..."

    users_to_delete = Repository::Unifi.list_radius_users.select do |user|
      user[:username].start_with?(Config::GUEST_USER_PREFIX) &&
        user[:username].split('-', 2)[1].to_i(36) < ((Time.now.to_f - Config::GUEST_USER_VALIDITY) * 1000).to_i
    end
    return if users_to_delete.empty?

    users_to_delete.each do |user|
      puts "deleting user #{user[:username]} (created at #{Time.at(user[:username].split('-', 2)[1].to_i(36) / 1000)})"
      Repository::Unifi.delete_radius_user(id: user[:id])
    rescue StandardError => e
      puts "could not delete #{user[:name]}: #{e}"
    end
  end

  def read_status
    # request real-time status
    # 1 = printer status
    # https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=118
    #
    # returns a status byte
    @printer << Escpos.sequence(0x10, 0x04, 1)
    @printer.readbyte
  end

  def create_and_print_user
    username = generate_username
    password = generate_password

    @printer << Escpos.sequence(Escpos::TXT_ALIGN_CT)
    if Repository::Unifi.strategy == Repository::Unifi::Strategy::Fake
      @printer << Escpos.sequence(Escpos::TXT_FONT_B)
      @printer << Escpos::Helpers.invert("  DEMO MODE  \n\n")
      @printer << Escpos.sequence(Escpos::TXT_FONT_A)
    end
    @printer << Escpos::Helpers.big(Config::HEADER)
    @printer << "\n\n"
    @printer << THAT_FOX.to_escpos
    @printer << "\n"
    @printer << Escpos.sequence(Escpos::TXT_ALIGN_LT)
    @printer << "Configure your wirelessly connected appliance\nas shown below:\n\n"
    begin
      Repository::Unifi.create_radius_user(
        username: username,
        password: password,
        vlan: 700
      )
      @printer << '        SSID: '
      @printer << Escpos::Helpers.bold(Config::SSID)
      @printer << "\n    Username: "
      @printer << Escpos::Helpers.bold(username.dup)
      @printer << "\n    Password: "
      @printer << Escpos::Helpers.bold(password.dup)
      @printer << "\n\nThese credentials are valid for 1 day.\n"
      if Config::ROOT_CA_URL
        @printer << "\nIf you are prompted for a certificate \nupon connecting, you can download it from:"
        @printer << "\n"
        @printer << Escpos::Helpers.underline(Config::ROOT_CA_URL)
        @printer << "\nor scan this QR code:"
        @printer << "\n\n"
        @printer << Escpos.sequence(Escpos::TXT_ALIGN_CT)
        @printer << qrcode(Config::ROOT_CA_URL)
      end
      if false
        # Unfortunately QR codes do not work with WPA-Enterprise ...
        @printer << "Too lazy to type all of that in?  Try out this\nspicy QR code:\n"
        @printer << Escpos.sequence(Escpos::TXT_ALIGN_CT)
        @printer << "\n"
        # @printer << qrcode("WIFI:T:WPA;S:#{ssid};P:#{access_code};;")
        # @printer << qrcode("WIFI:T:WPA2-EAP;S:#{ssid};P:\"#{password}\";I:#{username};E:PEAP;PH2:MSCHAPV2;;")
        @printer << qrcode("WIFI:S:#{ssid};I:#{username};P:#{password};;")
      end
    rescue => e
      @printer << "Or maybe not.  Beep and boop do not align.\n\n"
      @printer << Escpos.sequence(Escpos::TXT_FONT_B)
      @printer << Escpos::Helpers.bold(e.class.name)
      @printer << ': '
      @printer << e.message
      @printer << "\n"
      e.backtrace.each do |line|
        @printer << line
        @printer << "\n"
      end
      @printer << Escpos.sequence(Escpos::TXT_FONT_A)
    end
    @printer << "\n"
    @printer << Escpos.sequence(Escpos::TXT_ALIGN_LT)

    @printer << Escpos.sequence(Escpos::TXT_FONT_B)
    @printer << Config::FORTUNE_COMMAND.call

    @printer << Escpos.sequence(Escpos::TXT_ALIGN_CT)
    numbers, extra = generate_random_numbers
    @printer << "\nDeine Lotto 6 aus 45-Nummern lauten: #{numbers.join(', ')}.\nZusatzzahl: #{extra}\n\n"

    @printer << Escpos.sequence(Escpos::TXT_ALIGN_RT)
    @printer << "Generated at #{Time.now}\n"
    @printer << Escpos.sequence(Escpos::TXT_ALIGN_LT)
    @printer << Escpos.sequence(Escpos::TXT_FONT_A)

    7.times { @printer << "\n" }
    @printer << Escpos.sequence(Escpos::PAPER_FULL_CUT)
  end

  def generate_username
    [Config::GUEST_USER_PREFIX, (Time.now.to_f * 1000).to_i.to_s(36)].join
  end

  def generate_password
    SecureRandom.urlsafe_base64(8)
  end

  def generate_random_numbers
    (1..45)
      .to_a
      .shuffle
      .take(7)
      .then do |l|
        extra = l.pop
        [l, extra]
      end
  end

  def qrcode(data)
    data = data.dup.force_encoding('ASCII-8BIT')
    len = data.length + 3
    pl = len % 256
    ph = len / 256
    [
      # select model 2
      # https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=140
      Escpos.sequence(0x1d, 0x28, 0x6b, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00),

      # set size of module (last 0x03 = n -- depends on printer???)
      # https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=141
      Escpos.sequence(0x1d, 0x28, 0x6b, 0x03, 0x00, 0x31, 0x43, 0x07),

      # set n for error correction [48 x30 -> 7%] [49 x31-> 15%] [50 x32 -> 25%] [51 x33 -> 30%]
      # https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=142
      Escpos.sequence(0x1d, 0x28, 0x6b, 0x03, 0x00, 0x31, 0x45, 0x31),

      # store the data in the symbol storage area
      # https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=143
      Escpos.sequence(0x1d, 0x28, 0x6b, pl, ph, 0x31, 0x50, 0x30),

      data,

      # print symbol data in symbol storage area
      # https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=144
      Escpos.sequence(0x1d, 0x28, 0x6b, 0x03, 0x00, 0x31, 0x51, 0x30)
    ].join
  end
end
