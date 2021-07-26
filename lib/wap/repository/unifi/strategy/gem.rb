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

require 'unifi_gem'

module WAP
  module Repository
    module Unifi
      module Strategy
        class Gem
          # @param expire [Integer] time to expire in minutes (1440)
          # @param quota [Integer] how often this voucher can be used.  set this to 0 for unlimited use
          # @param note [String] a customisable note
          # @param up [Integer] upload bandwidth limit in Kbps
          # @param down [Integer] download bandwidth limit in Kbps
          # @param bytes [Integer] maximum amount of traffic they can make in MB
          # @return [String] the voucher code
          def create_voucher(expire: 1440, quota: 1, note: nil, up: nil, down: nil, bytes: nil)
            client
              .create_voucher(expire: expire, quota: quota, note: note, up: up, down: down, bytes: bytes)
              .tap(&method(:request_ok?))
              .then do |data|
                create_time = data.dig('data', 0, 'create_time')
                client.stat_voucher(create_time).dig('data', 0, 'code')
              end
          end

          # @param username [String] name of the user
          # @param password [String] password of the user
          # @param vlan [Integer] the assigned vlan
          def create_radius_user(username:, password:, vlan:)
            body = {
              name: username,
              x_password: password,
              vlan: vlan.to_s,
              tunnel_type: 13, # VLAN
              tunnel_medium_type: 6 # 802.X
            }

            client
              .class
              .post("/s/#{site}/rest/account", body: body.to_json)
              .parsed_response
              .then(&method(:request_ok?))
          end

          # @param id [String] internal id of the user as returned by #list_radius_users
          def delete_radius_user(id:)
            client
              .class
              .delete("/s/#{site}/rest/account/#{id}")
              .parsed_response
              .then(&method(:request_ok?))
          end

          def list_radius_users
            client
              .class
              .get("/s/#{site}/rest/account")
              .parsed_response
              .tap(&method(:request_ok?))
              .then { |data| data['data'] }
              .map { |obj| { id: obj.fetch('_id'), username: obj.fetch('name')} }
          end

          def list_devices
            client
              .class
              .get("/s/#{site}/stat/sta")
              .parsed_response
              .tap(&method(:request_ok?))
              .then { |data| data['data'] }
              .map do |data|
                data.transform_keys(&:to_sym).tap do |d|
                  d[:id] = d.delete(:_id)
                end
              end
          end

          # disconnects a wifi device
          # @param mac [String] mac address of the device, in the following
          #   format: 'aa:bb:cc:01:23:45'
          def disconnect_wifi_device(mac:)
            # kick-sta (reconnect) does not work here, so I need to block-sta
            # and immediately unblock-sta the device afterwards, otherwise the
            # client just stays connected
            %w[block-sta unblock-sta].each do |cmd|
              puts "#{Time.now} disconnect_wifi_device -> #{cmd} #{mac}"
              payload = JSON.dump(
                cmd: cmd,
                mac: mac
              )

              client
                .class
                .post("/s/#{site}/cmd/stamgr", body: payload)
                .parsed_response
                .then(&method(:request_ok?))
            end
          end

          private

          RESULT_OK = { 'rc' => 'ok' }.freeze
          private_constant :RESULT_OK

          def client
            @client ||= UnifiGem::Client.new(
              url: Config::UNIFI_URL,
              site: site,
              username: Config::UNIFI_USERNAME,
              password: Config::UNIFI_PASSWORD
            )
          end

          def site
            @site ||= Config::UNIFI_SITE
          end

          def request_ok?(data)
            return true if data['meta'] == RESULT_OK

            raise "expected meta to be #{RESULT_OK.inspect}, got #{data['meta'].inspect} instead"
          end
        end
      end
    end
  end
end

