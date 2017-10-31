function PageObject(arg){
    var _this = this;
    this.currNum = arg.currNum;
    this.pageCount = arg.pageCount;
    this.oUl = $("<ul class='pages'><li class='first'>First</li><li class='prev'>Prev</li><li class='next'>Next</li><li class='last'>Last</li></ul>");
    this.init = function(){
        this.initPageNum();
        $("#"+arg.appendId).html("");
        $("#"+arg.appendId).append(this.oUl);
    };

    this.initPageNum = function(){

        this.oUl.find(".num").remove();
        this.oUl.find(".shen").remove();
        var str = "";
        if(this.pageCount<=8){
            for(var i=1;i<=this.pageCount;i++){
                str += "<li class='num "+(this.currNum==i?"active":"")+"'>"+i+"</li>";
            }
        }else if(this.currNum<=4){
            for(var i=1;i<=5;i++){
                str += "<li class='num "+(this.currNum==i?"active":"")+"'>"+i+"</li>";
            }
            str += "<li class='shen'>...</li>";
            str += "<li class='num'>"+this.pageCount+"</li>";
        }else{
            str += "<li class='num'>1</li>";
            str += "<li class='shen'>...</li>";
            if(this.currNum+2<this.pageCount-1){
                for(var i=this.currNum-2;i<=this.currNum+2;i++){
                    str += "<li class='num "+(this.currNum==i?"active":"")+"'>"+i+"</li>";
                }
                str += "<li class='shen'>...</li>";
                str += "<li class='num'>"+this.pageCount+"</li>";
            }else{
                for(var i=this.pageCount-4;i<=this.pageCount;i++){
                    str += "<li class='num "+(this.currNum==i?"active":"")+"'>"+i+"</li>";
                }
            }
        }
        this.oUl.find(".next").before(str);

        if(this.currNum==1){
            this.oUl.find(".first").addClass("no");
            this.oUl.find(".prev").addClass("no");
        }else{
            this.oUl.find(".first").removeClass("no");
            this.oUl.find(".prev").removeClass("no");
        }
        if(this.currNum==this.pageCount){
            this.oUl.find(".last").addClass("no");
            this.oUl.find(".next").addClass("no");
        }else{
            this.oUl.find(".last").removeClass("no");
            this.oUl.find(".next").removeClass("no");
        }

        this.oUl.find(".num").on("click",function(){
            _this.currNum = parseInt($(this).html());
            _this.initPageNum();
            if(arg.callback){
                arg.callback(_this.currNum);
            }
        });
    };
    this.init();


    this.oUl.find(".first").on("click",function(){
        if($(this).hasClass("no")){
            return false;
        }
        _this.currNum = 1;
        _this.initPageNum();
        if(arg.callback){
            arg.callback(_this.currNum);
        }
    });

    this.oUl.find(".prev").on("click",function(){
        if($(this).hasClass("no")){
            return false;
        }
        _this.currNum = _this.currNum-1;
        _this.initPageNum();
        if(arg.callback){
            arg.callback(_this.currNum);
        }
    });

    this.oUl.find(".next").on("click",function(){
        if($(this).hasClass("no")){
            return false;
        }
        _this.currNum = _this.currNum+1;
        _this.initPageNum();
        if(arg.callback){
            arg.callback(_this.currNum);
        }
    });

    this.oUl.find(".last").on("click",function(){
        if($(this).hasClass("no")){
            return false;
        }
        _this.currNum = _this.pageCount;
        _this.initPageNum();
        if(arg.callback){
            arg.callback(_this.currNum);
        }
    });
}
