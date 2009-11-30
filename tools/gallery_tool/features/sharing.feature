Feature: I can share the same image in different galleries
  In order to use images in different galleries
  As someone with admin access to the gallery in question
  I want to be able to add other galleries images to the gallery
  And i want to be able to share the gallery with more people
  And i want to not be able to add images from galleries i may not access

Background:
  Given I exist
  And a user: "blue" exists with login: "blue"
  And I am logged in
  And a gallery: "mine" exists with title: "my precious"
  And i have admin access to that gallery
  And a gallery: "blues" exists with title: "none of my business"
  And the user: "blue" has admin access to that gallery
  And a gallery: "shared" exists with title: "blue and me - a family"
  And the user: "blue" has admin access to that gallery


Scenario: I can share my gallery with new users and they can access the gallery
  Given an image_asset exists with filename: "me_wants_to_see.jpg"
  And a showing exists with galllery: "shared" and asset: that image_asset
  And I have admin access to that gallery
  When I go to that gallery page
  Then I should see "Me want's to see!"
  And I should not see "No images in this Gallery"
