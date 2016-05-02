Page = function(title){
	this.title = title;
}

Page.prototype.greet = function(){
	console.log("This is your " + this.title + ".");
}