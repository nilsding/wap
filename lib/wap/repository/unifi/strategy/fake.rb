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

module WAP
  module Repository
    module Unifi
      module Strategy
        class Fake
          CURRENT_ISH_USER = ((Time.now.to_f - 600) * 1000).to_i.to_s(36)

          def create_voucher(*)
            Array.new(10) { (0..9).to_a.sample.to_s }.join
          end

          def create_radius_user(username:, password:, vlan:)
            true
          end

          def delete_radius_user(id:)
            true
          end

          def list_radius_users
            [{ id: '5fecb2de59e05f0012e50d16',
               username: 'cune' },
             { id: '5fecb40d59e05f0012e50dbb',
               username: 'foxy' },
             { id: '5ff322e259e05f0012c7b5a0',
               username: 'guest-kiinbc7l' },
             { id: '5ff3298159e05f0012c7b798',
               username: 'guest-kjiobo3w' },
             { id: '5ff3298c59f--current-ish',
               username: "guest-#{CURRENT_ISH_USER}" }]
          end

          def list_devices
            # these objects only contain a subset of what the controller
            # returns
            [
              { oui: 'Raspberr',
                id: '6000145259e05f0012837425',
                mac: 'dc:a6:32:f7:60:3f',
                is_wired: true,
                name: 'Pi Hole',
                network: 'LAN',
                ip: '192.168.1.53' },
              { oui: '',
                id: '5ffb224d59e05f001277952b',
                mac: 'ac:87:a3:6d:2a:18',
                is_wired: false,
                hostname: 'iPad-2',
                essid: 'Fuchsbau',
                network: 'LAN',
                ip: '192.168.1.52',
                :'1x_identity' => 'cune' },
              { oui: '',
                id: '5fecb58b59e05f0012e50e08',
                mac: 'a8:60:b6:f9:85:72',
                is_wired: false,
                hostname: 'FuchsPhone',
                essid: 'Fuchsbau',
                network: 'LAN',
                ip: '192.168.1.34',
                :'1x_identity' => 'foxy' },
              {
                oui: 'AsustekC',
                id: '5fd5106659e05f00119c1b7a',
                mac: '88:d7:f6:28:ae:cd',
                is_wired: false,
                hostname: 'Megasus',
                essid: 'Fuchsbau',
                network: 'LAN',
                ip: '192.168.1.142',
                :'1x_identity' => 'guest-kiinbc7l' },
              {
                oui: 'Apple',
                id: '5fd5106659e05f00119c1b7a',
                mac: '38:c9:86:7b:d7:b3',
                is_wired: false,
                hostname: 'MacBook',
                essid: 'Fuchsbau',
                network: 'LAN',
                ip: '192.168.1.69',
                :'1x_identity' => 'guest-kjiobo3w' },
              {
                oui: 'Apple',
                id: '5fd5106659f--current-ish',
                mac: 'a8:20:66:3b:52:34',
                is_wired: false,
                hostname: 'MacBook-current',
                essid: 'Fuchsbau',
                network: 'LAN',
                ip: '192.168.1.75',
                :'1x_identity' => "guest-#{CURRENT_ISH_USER}" },
              { oui: 'Apple',
                id: '604a4855397ac2001237b7bf',
                mac: '8c:85:90:41:ba:63',
                is_wired: true,
                hostname: 'e621',
                name: 'e621',
                network: 'LAN',
                ip: '192.168.1.224' }]
          end

          def disconnect_wifi_device(mac:)
            true
          end
        end
      end
    end
  end
end
