# Copyright (c) 2020, salesforce.com, inc.
# All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause

from robot.libraries.BuiltIn import BuiltIn


class BaseV4SPage:
    @property
    def v4s(self):
        return self.builtin.get_library_instance("v4s")

    @property
    def pageobjects(self):
        return self.builtin.get_library_instance("cumulusci.robotframework.PageObjects")
