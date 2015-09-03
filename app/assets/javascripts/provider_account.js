$('.select.required.form-control').change(function(event) {
  if ($(this).val() != 'smtp') {
    $('.copy-old-letters').html('<input value="0" type="hidden" name="provider_account[copy_old_letters]">' + 
    '<label class="checkbox"><input class="boolean optional checkbox" type="checkbox"' + 
    ' value="1" checked="checked" name="provider_account[copy_old_letters]" ' + 
    'id="provider_account_copy_old_letters"> Copy old letters</label>');
  } else {
    $('.copy-old-letters').html('');
  }
});