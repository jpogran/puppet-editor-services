# Change Log

All notable changes to the "puppet-editor-services" repository will be documented in this file.

Check [Keep a Changelog](http://keepachangelog.com/) for recommendations on how to structure this file.

## Unreleased

## 0.24.0 - 2020-01-28

### Fixed

- ([GH-199](https://github.com/lingua-pupuli/puppet-editor-services/issues/199)) Fixes for Puppet 5.5.18

### Changed

- ([GH-213](https://github.com/lingua-pupuli/puppet-editor-services/issues/213)) Gather Facts from the Sidecar instead of the Server process

## 0.23.0 - 2019-12-04

### Added

- ([GH-198](https://github.com/lingua-pupuli/puppet-editor-services/issues/198)) Added the Puppetfile Resolver for more in-depth Puppetfile validation
- ([GH-94](https://github.com/lingua-pupuli/puppet-editor-services/issues/94)) Added better intellisense when inside Bolt plans

### Fixed

- ([GH-199](https://github.com/lingua-pupuli/puppet-editor-services/issues/199)) Fixes for Puppet 6.11.0
- ([GH-139](https://github.com/lingua-pupuli/puppet-editor-services/issues/139)) Provide completions for defined types

### Changed

- ([GH-193](https://github.com/lingua-pupuli/puppet-editor-services/issues/193)) Refactor the TCP and STDIO servers, protocols and handlers
- ([Commit](https://github.com/lingua-pupuli/puppet-editor-services/commit/c3bd86f5b9a237b92f4c0e2d6c2ddc7aa5b0d9e5)) Update puppet-lint to version 2.4.2

## 0.22.0 - 2019-09-20

### Added

- ([GH-181](https://github.com/lingua-pupuli/puppet-editor-services/issues/181)) Added completion for resource-like class ([Julio Sueiras](https://github.com/juliosueiras))
- ([GH-177](https://github.com/lingua-pupuli/puppet-editor-services/issues/177)) Add auto-align hash rocket formatter
- ([GH-174](https://github.com/lingua-pupuli/puppet-editor-services/issues/174)) Understand Puppet Data Types and hover provider support

### Fixed

- ([GH-169](https://github.com/lingua-pupuli/puppet-editor-services/issues/169)) Respond to protocol dependant messages correctly

## 0.21.0 - 2019-08-26

### Added

- ([GH-144](https://github.com/lingua-pupuli/puppet-editor-services/issues/144)) Add a Signature Helper Provider
- ([GH-163](https://github.com/lingua-pupuli/puppet-editor-services/issues/163)) Add aggregate sidecar tasks

### Fixed

- ([GH-55](https://github.com/lingua-pupuli/puppet-editor-services/issues/55)) Debug Server is now supported on Puppet 6

### Changed

- ([GH-106](https://github.com/lingua-pupuli/puppet-editor-services/issues/106)) Update puppet-lint to 2.3.6
- ([GH-167](https://github.com/lingua-pupuli/puppet-editor-services/issues/167)) Refactor Language Server inmemory caching

## 0.20.0 - 2019-07-16

### Added

- ([GH-141](https://github.com/lingua-pupuli/puppet-editor-services/issues/141)) [Puppet4 API Project Task 7] Modify the Puppet Function loading to use all of the new Puppet 4 API features
- ([GH-137](https://github.com/lingua-pupuli/puppet-editor-services/issues/137)) [Puppet4 API Project Task 4-6] Load Puppet Custom Types, Defined Types and Classes via Puppet API v4
- ([GH-121](https://github.com/lingua-pupuli/puppet-editor-services/issues/121)) [Puppet4 API Project Task 1-3] Load Puppet Functions via Puppet API v4 and present as Puppet API v3 functions

### Fixed

- ([GH-147](https://github.com/lingua-pupuli/puppet-editor-services/issues/147)) Error generating node graph
- ([GH-129](https://github.com/lingua-pupuli/puppet-editor-services/issues/129)) Better Bolt/Puppet plan detection

## 0.19.1 - 2019-05-31

### Fixed

- ([GH-132](https://github.com/lingua-pupuli/puppet-editor-services/issues/132)) Suppress $stdout usage for STDIO transport
- ([GH-118](https://github.com/lingua-pupuli/puppet-editor-services/issues/118)) Fail gracefully when critical gems cannot load

## 0.19.0 - 2019-03-24

### Added

- ([GH-111](https://github.com/lingua-pupuli/puppet-editor-services/issues/111)) Add puppet-version command line argument

### Fixed

- ([Commit](https://github.com/lingua-pupuli/puppet-editor-services/commit/7d14081eaa793a0382321391ba234db8126c5916)) Use UTF8 for JSON files in the Language Server Sidecar
- ([GH-113](https://github.com/lingua-pupuli/puppet-editor-services/issues/113)) Rescue errors when running Facter 2.x

### Changed

- ([GH-110](https://github.com/lingua-pupuli/puppet-editor-services/issues/110)) Autogenerate Ruby Language Server Protocol files from Typescript

## 0.18.0 - 2019-02-05

### Added

- ([GH-24](https://github.com/lingua-pupuli/puppet-editor-services/issues/24)) Allow parsing of manifests in tasks mode

### Fixed

- ([Commit](https://github.com/lingua-pupuli/puppet-editor-services/commit/1a294920702dc95ff11e50c68e4fa12e5da09d98)) Fix validation of puppetfiles
- ([Commit](https://github.com/lingua-pupuli/puppet-editor-services/commit/6758afaefcde90809a7b2457c23c72fa487a2dd7)) Fix parsing at beginning of a document

## 0.17.0 - 2018-12-14

### Added

- ([GH-20](https://github.com/lingua-pupuli/puppet-editor-services/issues/20)) Add support for Control Repositories for intellisense e.g. hover, completion
- ([GH-88](https://github.com/lingua-pupuli/puppet-editor-services/issues/20)) Add a workspace symbol provider

### Changed

- ([GH-35](https://github.com/lingua-pupuli/puppet-editor-services/issues/35)) Update Language Server command arguments to be like Sidecar

## 0.16.0 - 2018-11-30

### Added

- ([GH-75](https://github.com/lingua-pupuli/puppet-editor-services/issues/75)) Add a node completion item snippet
- ([GH-68](https://github.com/lingua-pupuli/puppet-editor-services/issues/68)) Language Server should evaluate the locally edited workspace

### Fixed

- ([GH-67](https://github.com/lingua-pupuli/puppet-editor-services/issues/67)) Make resource completion smarter
- ([GH-34](https://github.com/lingua-pupuli/puppet-editor-services/issues/34)) Autocomplete and hover should retrieve defined types and classes

## 0.15.1 - 2018-10-30

### Fixed

- ([GH-66](https://github.com/lingua-pupuli/puppet-editor-services/issues/66)) Go to defintion does not work with paths with leading slash

## 0.15.0 - 2018-08-18

### Added

- ([GH-56](https://github.com/lingua-pupuli/puppet-editor-services/issues/56)) Add DocumentSymbol Support
- ([GH-40](https://github.com/lingua-pupuli/puppet-editor-services/issues/40)) Add Sidecar process for the Language Server

### Fixed

- ([GH-54](https://github.com/lingua-pupuli/puppet-editor-services/issues/54)) Support Puppet 6 in the Language Server
- ([GH-51](https://github.com/lingua-pupuli/puppet-editor-services/issues/51)) Fixed handling of errors during class loading

## 0.14.0 - 2018-08-17

### Fixed

- ([GH-49](https://github.com/lingua-pupuli/puppet-editor-services/issues/49)) Prevent an infinite loop when using stdio

## 0.13.0 - 2018-07-21

### Changed

- ([GH-36](https://github.com/lingua-pupuli/puppet-editor-services/issues/36)) Use automatic port assignment as default

### Fixed

- ([GH-31](https://github.com/lingua-pupuli/puppet-editor-services/issues/31)) Use canonical names for line based breakpoints
- ([GH-46](https://github.com/lingua-pupuli/puppet-editor-services/issues/46)) Detect Puppet Environment correctly
- Minor fixes for rubocop

## 0.12.0 - 2018-06-01

### Added

- ([GH-28](https://github.com/lingua-pupuli/puppet-editor-services/issues/28)) Added basic Puppetfile validation

### Changed

- ([GH-22](https://github.com/lingua-pupuli/puppet-editor-services/issues/22)) Refactored language server files to have consistent names

### Fixed

- ([GH-26](https://github.com/lingua-pupuli/puppet-editor-services/issues/26)) `.puppet-lint.rc` was ignored in Control Repos
- ([GH-14](https://github.com/lingua-pupuli/puppet-editor-services/issues/14)) Ignore environmentpath puppet setting if it does not exist
- ([GH-10](https://github.com/lingua-pupuli/puppet-editor-services/issues/10)) Disabled the file cache if temp directory doesn't exist

## 0.11.0 - 2018-04-26

- ([GH-11](https://github.com/lingua-pupuli/puppet-editor-services/issues/11)) Refactor the transport layers to loosen object coupling
- ([GH-11](https://github.com/lingua-pupuli/puppet-editor-services/issues/11)) Fix STDIO server
- Stop bad logfile destinations from crashing the language and debug servers
- Add a packaging process
- Rename PuppetVSCode namespace to editor services
- Move the Editor Services out of the VS Code extension into a separate project

## 0.10.0 - 2018-03-29

- ([GH-218](https://github.com/jpogran/puppet-vscode/issues/218)) Validate EPP files
- ([GH-244](https://github.com/jpogran/puppet-vscode/issues/244)) Update puppet-lint to 2.3.5
- ([GH-245](https://github.com/jpogran/puppet-vscode/issues/245)) Update puppet-lint to 2.3.5
- ([GH-216](https://github.com/jpogran/puppet-vscode/issues/216)) Better syntax highlighting
- ([GH-214](https://github.com/jpogran/puppet-vscode/issues/214)) Updated readme for pdk 1.3.X
- ([GH-225](https://github.com/jpogran/puppet-vscode/issues/225)) Readd Local Workspace comand line option
- ([GH-231](https://github.com/jpogran/puppet-vscode/issues/231)) Make Document Validation asynchronous
- ([GH-236](https://github.com/jpogran/puppet-vscode/issues/236)) Remove the preload option
- ([GH-236](https://github.com/jpogran/puppet-vscode/issues/236)) Add experimental file cache option

## 0.9.0 - 2018-02-01

- ([GH-50](https://github.com/jpogran/puppet-vscode/issues/50)) Add document formatter for puppet-lint
- ([GH-204](https://github.com/jpogran/puppet-vscode/issues/204)) Fix debug server for Puppet 4.x

## 0.8.0 - 2017-11-24

- ([GH-180](https://github.com/jpogran/puppet-vscode/issues/180)) Backslashes in File Path do not display in Node Graph
- ([GH-100](https://github.com/jpogran/puppet-vscode/issues/100)) Experimental Puppet-Debugger
- ([PR-194](https://github.com/jpogran/puppet-vscode/pull/194)) Fix logger in PDK New Task
- ([PR-195](https://github.com/jpogran/puppet-vscode/pull/195)) Do not error in validation exception handler
- ([GH-187](https://github.com/jpogran/puppet-vscode/issues/187)) Add stdio mode to language server
- (maint) Fix rubocop violations

## 0.7.2 - 2017-11-01

- ([GH-165](https://github.com/jpogran/puppet-vscode/issues/165)) Broken readme link
- ([GH-88](https://github.com/jpogran/puppet-vscode/issues/88))  Rework Node Graph Preview to use local svg
- ([GH-154](https://github.com/jpogran/puppet-vscode/issues/154)) Use hosted JSON schema files
- ([GH-169](https://github.com/jpogran/puppet-vscode/issues/169)) Fix bug in sytanx highlighting
- ([GH-167](https://github.com/jpogran/puppet-vscode/issues/167)) Add PDK New Task command
- ([GH-156](https://github.com/jpogran/puppet-vscode/issues/156)) Document restarting Puppet extension command
- ([GH-177](https://github.com/jpogran/puppet-vscode/issues/177)) Remove detection of Puppet VERSION file
- ([GH-175](https://github.com/jpogran/puppet-vscode/issues/175)) Fix 'could not find valid version of Puppet'

## 0.7.1 - 2017-09-29

- ([GH-157](https://github.com/jpogran/puppet-vscode/issues/157)) Puppet Resource command hidden

## 0.7.0 - 2017-09-22

- ([GH-115](https://github.com/jpogran/puppet-vscode/issues/115)) Add Puppet Development Kit (PDK) integration
- ([GH-136](https://github.com/jpogran/puppet-vscode/issues/136)) Create a better UI experience while Puppet loads
- ([GH-61](https://github.com/jpogran/puppet-vscode/issues/61))  Create a better experience when language client fails
- ([GH-135](https://github.com/jpogran/puppet-vscode/issues/135)) Fix incorrect logger when a client error occurs
- ([GH-129](https://github.com/jpogran/puppet-vscode/issues/129)) Honor inline puppet lint directives
- ([GH-133](https://github.com/jpogran/puppet-vscode/issues/133)) Fix issue with puppet 5.1.0
- ([GH-122](https://github.com/jpogran/puppet-vscode/issues/122)) Show upgrade message with changelog
- ([GH-120](https://github.com/jpogran/puppet-vscode/issues/120)) Allow custom Puppet agent installation directory
- ([GH-126](https://github.com/jpogran/puppet-vscode/issues/126)) Fix completion provider with Puppet 5.2.0
- ([GH-110](https://github.com/jpogran/puppet-vscode/issues/110)) Add extension analytics
- ([GH-138](https://github.com/jpogran/puppet-vscode/issues/138)) Set extension analytics to prod
- ([GH-109](https://github.com/jpogran/puppet-vscode/issues/109)) Randomize languageserver port
- ([GH-111](https://github.com/jpogran/puppet-vscode/issues/111)) Parse puppet-lint.rc in module directory

## 0.6.0 - 2017-08-08

- Fix packaging error where language server was not included

## 0.5.3 - 2017-08-08

- ([GH-92](https://github.com/jpogran/puppet-vscode/issues/92)) Added context menus for Puppet Resource and Nodegraph preview
- ([GH-98](https://github.com/jpogran/puppet-vscode/issues/98)) Improve language server function and type loading
- ([GH-52](https://github.com/jpogran/puppet-vscode/issues/52)) JSON validation and schema for metadata.json
- ([GH-47](https://github.com/jpogran/puppet-vscode/issues/47)) Fixes pending language server tests
- ([GH-45](https://github.com/jpogran/puppet-vscode/issues/45)) Fix runocop violations for language tcp server
- ([GH-89](https://github.com/jpogran/puppet-vscode/issues/89)) Document support for linux in readme
- ([GH-64](https://github.com/jpogran/puppet-vscode/issues/64)) Additional language server tests
- ([GH-103](https://github.com/jpogran/puppet-vscode/issues/103)) Extension now supports puppet-lint rc files
- ([GH-99](https://github.com/jpogran/puppet-vscode/issues/99)) Improved client README and Gallery page

## 0.4.6 - 2017-06-29

### Changed

- Updated links in README
- Added more information to package manifest
- Minor updates to README

## 0.4.5 - 2017-06-27

### Changed

- Updated badge link location in README

## 0.4.2 - 2017-06-27

### Changed

- Updated badge links to use proper extension id

## 0.4.0 - 2017-06-27

### Added

- A functional Language Server for the Puppet language
  - Real time puppet lint
  - Auto-complete and Hover support for many puppet language facets
  - Auto-complete and Hover support for facts
  - 'puppet resource' support
  - Preview node graph support
- Tested on older Puppet versions (4.7 LTS series)
- Added testing on Travis and Appveyor

### Fixed

- Completion and Hover provider didn't load puppet modules
- Implemented textDocument/didClose notification
- Fixed completion at file beginning on new lines and on keywords

## 0.0.3 - 2017-05-08

### Added

- Puppet Parser validate linter added

## 0.0.2 - 2017-05-04

### Added

- Puppet Resource and Puppet Module commands.

## 0.0.1 - 2017-04-10

### Added

- Initial release of the puppet extension.
