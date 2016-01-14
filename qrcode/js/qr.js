function read(a)
{
    $("#qr-code-value").text(a);
    $("#xGif").hide();
   	$("#tickGif").show();

   	window.setTimeout(relocate,1000);
}

function relocate(){

	setInterval(function () {
		    window.location = 'http://google.com';
     
    }, 1500);
}
    
qrcode.callback = read;