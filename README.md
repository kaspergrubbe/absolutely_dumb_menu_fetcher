# Absolutely Dumb Menu Fetcher

This Ruby application is designed to fetch today's menu from Meyers.dk in the absolute dumbest way possible. **If you're looking for a sophisticated solution, you're in the wrong place!**

- We wanted to show the menu from Meyers on a screen in the office.
- I didn't want to spend time parsing HTML or re-designing the output.

## The solution is mega dumb:

- Spawn a Firefox browser window through Selenium
- Navigate to https://meyers.dk/erhverv/frokostordning/ugens-menuer/
- Decline cookies
- Hide the "FAQ and contact" overlay
- Scroll down to the menu
- Hide the menu navigation buttons
- Hide the menu PDF downloader HTML controls
- Take a screenshot of the current viewport

With the screenshot we then get a lot of extra data because of the footer on the page, therefore the final steps are:

- Cut off the screenshot image using image-in-image search
- Generate a kitchen.html file and upload it to S3

