# WiFi Access Printer <img align="right" src="misc/demo.gif">

A small thing to give guests access to your WiFi with style.

## Requirements

- Ruby 2.7
- A thermal printer that talks ESC/POS and has a "Feed" button, connected either via USB or ethernet
- A UniFi controller, which
  - has a WiFi Access Point configured with WPA-Enterprise
  - and has a USG adopted which acts as a RADIUS server

## Installation

0. Copy `config.rb.example` to `config.rb` and configure it to match your setup
1. Install the bundle: `bundle install`
2. Run the application using `./exe/wap` (run it with `./exe/wap fake` for a testing mode that does not make calls to UniFi)

## Usage

Push the "Feed" button on the thermal printer to receive a new access code that's valid for 24 hours.
