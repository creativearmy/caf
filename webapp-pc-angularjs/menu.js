//$(".menu ul li ul").css('display', 'block');
function ShowHid(that){
	var ul = $(that).next();
	if(ul.css('display') == "none")
		ul.css('display', 'block');
	else
		ul.css('display', 'none');
}