# frozen_string_literal: true
#
# WAP - give your guests WiFi Access, Printed
# Copyright (C) 2021, 2022 Georg Gadinger <nilsding@nilsding.org>
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

require "securerandom"

module WAP
  module PasswordGenerator
    COLOURS = %w[
      azure
      black
      blue
      brown
      crimson
      cyan
      green
      lime
      magenta
      orange
      pink
      purple
      red
      teal
      turquoise
      violet
      white
      yellow
    ].freeze

    ANIMALS = %w[
      badger
      bee
      camel
      cat
      cheeto
      dog
      dolphin
      dragon
      fox
      horse
      jackdaw
      kangaroo
      ocelot
      octopus
      parrot
      penguin
      platypus
      protogen
      raccoon
      raven
      sealion
      shark
      snake
      synth
      tiger
      wolf
    ].freeze

    module_function

    def generate
      titlecase = ->(str) { str.gsub(/^(.)(.+)/) { "#{$1.upcase}#{$2}" } }

      [
        COLOURS.sample(random: SecureRandom).then(&titlecase),
        ANIMALS.sample(random: SecureRandom).then(&titlecase),
        SecureRandom.random_number(10..99).to_s
      ].join
    end
  end
end
