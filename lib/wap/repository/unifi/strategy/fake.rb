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
               username: 'Racc' },
             { id: '5fecb40d59e05f0012e50dbb',
               username: 'foxy' },
             { id: '5ff322e259e05f0012c7b5a0',
               username: 'guest-kiinbc7l' },
             { id: '5ff3298159e05f0012c7b798',
               username: 'guest-kjiobo3w' },
             { id: '5ff3298c59f--current-ish',
               username: "guest-#{((Time.now.to_f - 600) * 1000).to_i.to_s(36)}" }]
          end
        end
      end
    end
  end
end
