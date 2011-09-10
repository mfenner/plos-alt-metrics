// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var FormTracker = {} 
FormTracker = { 
  disableForm: function() { 
    Element.show('form-indicator'); 
    Form.disable('form'); 
    }, 
  enableForm: function(form) { 
    Element.hide('form-indicator'); 
    Form.enable('form'); 
  } 
}