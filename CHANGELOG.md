# Changelog

All notable changes to this project will be documented in this file.

## [1.3.12](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.11...1.3.12) (2025-06-16)


### Bug Fixes

* add sqs url ([#30](https://github.com/acai-consulting/terraform-aws-lambda/issues/30)) ([dbf599a](https://github.com/acai-consulting/terraform-aws-lambda/commit/dbf599a3d97555ff387d2e2c8ff100763e5c169f))

## [1.3.11](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.10...1.3.11) (2025-06-04)


### Bug Fixes

* Update readme ([#28](https://github.com/acai-consulting/terraform-aws-lambda/issues/28)) ([69ce5e6](https://github.com/acai-consulting/terraform-aws-lambda/commit/69ce5e654bede4048806ac2b3251ac54d848c124))

## [1.3.10](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.9...1.3.10) (2025-06-04)


### Bug Fixes

* add execution_iam_role_settings.permissions_fully_externally_managed ([#27](https://github.com/acai-consulting/terraform-aws-lambda/issues/27)) ([fbf154e](https://github.com/acai-consulting/terraform-aws-lambda/commit/fbf154ec136ec28bf51734840393e4a975aa1164))

## [1.3.9](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.8...1.3.9) (2025-05-20)


### Bug Fixes

* iam policy-name - remove inline check for suffix ([#26](https://github.com/acai-consulting/terraform-aws-lambda/issues/26)) ([3e44a3b](https://github.com/acai-consulting/terraform-aws-lambda/commit/3e44a3b4be0ea4d8840f9c380ed2626c45988624))

## [1.3.8](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.7...1.3.8) (2025-05-06)


### Bug Fixes

* add permissions for VPC ([#25](https://github.com/acai-consulting/terraform-aws-lambda/issues/25)) ([75c8d9c](https://github.com/acai-consulting/terraform-aws-lambda/commit/75c8d9c1676e358bbec497cffe717dff70ad8558))

## [1.3.7](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.6...1.3.7) (2024-08-30)


### Bug Fixes

* add validation and 5th use-case for files_to_inject ([c816ec9](https://github.com/acai-consulting/terraform-aws-lambda/commit/c816ec9b48852cb46b77500126a7d6c4039faf87))

## [1.3.6](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.5...1.3.6) (2024-07-05)


### Bug Fixes

* refactor generation of Lambda package ([#23](https://github.com/acai-consulting/terraform-aws-lambda/issues/23)) ([0552783](https://github.com/acai-consulting/terraform-aws-lambda/commit/0552783eb17ad239ae0c58115c3971e6540c5695))

## [1.3.5](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.4...1.3.5) (2024-06-27)


### Bug Fixes

* inject files again with null_resource  ([#22](https://github.com/acai-consulting/terraform-aws-lambda/issues/22)) ([f4b03e3](https://github.com/acai-consulting/terraform-aws-lambda/commit/f4b03e3cd8f3a55ab09b252d7626a954e4c8f737))

## [1.3.4](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.3...1.3.4) (2024-06-07)


### Bug Fixes

* use local_file for injection ([#21](https://github.com/acai-consulting/terraform-aws-lambda/issues/21)) ([01a5118](https://github.com/acai-consulting/terraform-aws-lambda/commit/01a5118f50476481dd4556d6585117e44caffae9))

## [1.3.3](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.2...1.3.3) (2024-06-07)


### Bug Fixes

* injection to handle ` ([#20](https://github.com/acai-consulting/terraform-aws-lambda/issues/20)) ([645c444](https://github.com/acai-consulting/terraform-aws-lambda/commit/645c4444ca26be839cf6ca2219740aebd102b0e1))

## [1.3.2](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.1...1.3.2) (2024-05-09)


### Bug Fixes

* add sqs management permissions ([#19](https://github.com/acai-consulting/terraform-aws-lambda/issues/19)) ([ad88f2a](https://github.com/acai-consulting/terraform-aws-lambda/commit/ad88f2a205674f5419fb2d09c665d0ac1ba644dd))

## [1.3.1](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.3.0...1.3.1) (2024-04-30)


### Bug Fixes

* add correct layer_arn_list ([#18](https://github.com/acai-consulting/terraform-aws-lambda/issues/18)) ([b62646f](https://github.com/acai-consulting/terraform-aws-lambda/commit/b62646f713324099391f743f3fe09c92ca29491e))

## [1.3.0](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.2.3...1.3.0) (2024-04-22)


### Features

* Add optional injection of additional files into lambda package ([#17](https://github.com/acai-consulting/terraform-aws-lambda/issues/17)) ([051e110](https://github.com/acai-consulting/terraform-aws-lambda/commit/051e1103ccefdd192e3d7c7676f40ba6324a6192))

## [1.2.3](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.2.2...1.2.3) (2024-04-15)


### Bug Fixes

* central_collector ([#16](https://github.com/acai-consulting/terraform-aws-lambda/issues/16)) ([874f97e](https://github.com/acai-consulting/terraform-aws-lambda/commit/874f97e0c2e174d20141f7fe158143f4aa28df08))

## [1.2.2](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.2.1...1.2.2) (2024-04-15)


### Bug Fixes

* optional error_handling.central_collector.target_arn ([#15](https://github.com/acai-consulting/terraform-aws-lambda/issues/15)) ([db74230](https://github.com/acai-consulting/terraform-aws-lambda/commit/db7423060029d02e7d80f3ee24798c15ba41856f))

## [1.2.1](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.2.0...1.2.1) (2024-04-14)


### Bug Fixes

* Skip ckv aws 338 ([#14](https://github.com/acai-consulting/terraform-aws-lambda/issues/14)) ([763f94b](https://github.com/acai-consulting/terraform-aws-lambda/commit/763f94ba279c614b0bb145f66ddf5e027e4d828f))

## [1.2.0](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.1.6...1.2.0) (2024-04-13)


### Features

* refactor error-handling  ([#13](https://github.com/acai-consulting/terraform-aws-lambda/issues/13)) ([02724fc](https://github.com/acai-consulting/terraform-aws-lambda/commit/02724fc03bb86eeeeece04a855bf2a45aaff1300))

## [1.1.6](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.1.5...1.1.6) (2024-04-10)


### Bug Fixes

* update tagging ([#12](https://github.com/acai-consulting/terraform-aws-lambda/issues/12)) ([b290d99](https://github.com/acai-consulting/terraform-aws-lambda/commit/b290d99d467a987773fb3b9dc2f1147b1dbcfb06))

## [1.1.5](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.1.4...1.1.5) (2024-04-10)


### Bug Fixes

* add compliance to checkov ([#11](https://github.com/acai-consulting/terraform-aws-lambda/issues/11)) ([4c3d108](https://github.com/acai-consulting/terraform-aws-lambda/commit/4c3d10865afdd0f6b478464f40236dcd1a7d6e10))

## [1.1.4](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.1.3...1.1.4) (2024-04-10)


### Bug Fixes

* add default tags, including injected version ([#10](https://github.com/acai-consulting/terraform-aws-lambda/issues/10)) ([7bcea77](https://github.com/acai-consulting/terraform-aws-lambda/commit/7bcea773b6e61030a1947cf305b219acb24a2777))

## [1.1.3](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.1.2...1.1.3) (2024-04-10)


### Bug Fixes

* Introduce DeadLetterQueue ([#9](https://github.com/acai-consulting/terraform-aws-lambda/issues/9)) ([0b931c7](https://github.com/acai-consulting/terraform-aws-lambda/commit/0b931c73f82aacf8c559bfac49bcd7a1cab72253))

## [1.1.2](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.1.1...1.1.2) (2024-04-09)


### Bug Fixes

* add trigger as output ([#8](https://github.com/acai-consulting/terraform-aws-lambda/issues/8)) ([126d3a8](https://github.com/acai-consulting/terraform-aws-lambda/commit/126d3a8aee9c352c52d9739b6ce4e0c9f4c10d51))

## [1.1.1](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.1.0...1.1.1) (2024-04-07)


### Bug Fixes

* permission policy json list ([#7](https://github.com/acai-consulting/terraform-aws-lambda/issues/7)) ([14fa226](https://github.com/acai-consulting/terraform-aws-lambda/commit/14fa226813997bb32173645d3f250a1f45b7dbd1))

## [1.1.0](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.0.1...1.1.0) (2024-04-07)


### Features

* Adjust iam output ([#6](https://github.com/acai-consulting/terraform-aws-lambda/issues/6)) ([a453d95](https://github.com/acai-consulting/terraform-aws-lambda/commit/a453d95079b4742aa5035bb695f86de0b3581f42))

## [1.0.1](https://github.com/acai-consulting/terraform-aws-lambda/compare/1.0.0...1.0.1) (2024-04-06)


### Bug Fixes

* Update readme ([#4](https://github.com/acai-consulting/terraform-aws-lambda/issues/4)) ([bb916b3](https://github.com/acai-consulting/terraform-aws-lambda/commit/bb916b30c945ece74f2131c05aab5c799879107f))

## 1.0.0 (2024-04-06)


### Features

* Initial version ([#2](https://github.com/acai-consulting/terraform-aws-lambda/issues/2)) ([44a0331](https://github.com/acai-consulting/terraform-aws-lambda/commit/44a033199aecd5fe2f8d5ebf19361855a465c19e))
