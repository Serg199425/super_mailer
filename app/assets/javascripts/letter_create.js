$(document).ready(function () {
  $("#letter_to").tagsInput({ width: '30%', height: '30px', defaultText: 'To'});
});


function add_attachment() {
  var index = $('.attachments-container').children().length
  $('.attachments-container').append('<div class="input file optional letter_attachments_file">' + 
    '<input class="file optional" type="file" name="letter[attachments_attributes][' + index + '][file]"' +
     'id="letter_attachments_attributes_'+ index + '_file"></div>');
}

function remove_attachment() {
  if ($('.attachments-container').children().length > 0)
    $('.attachments-container').children().last().remove()
}
