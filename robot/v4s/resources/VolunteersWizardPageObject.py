# Copyright (c) 2020, salesforce.com, inc.
# All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause


from cumulusci.robotframework.pageobjects import pageobject
from v4s_locators import v4s_lex_locators
from BaseObjects import BaseV4SPage


@pageobject("VolunteersWizard")
class VolunteersWizardPage(BaseV4SPage):

    def go_to_vf_page(self):
        """ Navigates to the Volunteers Wizard page and Verify we are on correct page"""

        url = self.cumulusci.org.lightning_base_url
        url = "{}/lightning/n/Volunteers_Wizard".format(url)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        self.portal.select_frame_with_value('campaign information')
        locator = v4s_lex_locators["application_locators"]["design_page_header"].format("FoundationConnect")
        self.selenium.wait_until_page_contains_element(locator)
