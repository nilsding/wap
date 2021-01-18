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

require 'receptacle'
require 'wap/repository/unifi/strategy/gem'
require 'wap/repository/unifi/strategy/fake'

module WAP
  module Repository
    module Unifi
      include Receptacle::Repo

      mediate :create_voucher
      mediate :create_radius_user
      mediate :delete_radius_user
      mediate :list_radius_users

      strategy Strategy::Gem
    end
  end
end
