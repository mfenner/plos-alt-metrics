Feature: Adding works for user

  Scenario: Add works for Microsoft Academic Search author identifier
   Given a Microsoft Academic Search author identifier 7086796 
   When the script is run
   Then the number of works should be 16