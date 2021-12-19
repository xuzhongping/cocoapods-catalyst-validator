# cocoapods-catalyst-validator

A cocoapods plugin for detecting whether the binary files in the integrated Pod support catalyst.

## Installation

    $ gem install cocoapods-catalyst-validator

## Usage

    plugin 'cocoapods-catalyst-validator'


    target AExample do
        use_catalyst_verify! [:warning/:error]

        pod 'SomePod'
    end
