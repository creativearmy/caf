function PageObject(arg){
    var _this = this;
    this.currNum = arg.currNum;
    this.pageCount = arg.pageCount;
    this.oUl = $("<ul class='pages'><li class='first'>首页</li><li class='prev'>上一页</li><li class='next'>下一页</li><li class='last'>末页</li></ul>");
    this.init = function(){
        this.initPageNum();
        $("#"+arg.appendId).html("");
        $("#"+arg.appendId).append(this.oUl);
    };
    //排列分页的数字
    this.initPageNum = function(){
        //清除以前分页的数字，重新排列分页数字
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
        //设置首页、上一页、下一页、末页是否可以点击
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
        //点击页数 - 事件绑定
        this.oUl.find(".num").on("click",function(){
            _this.currNum = parseInt($(this).html());
            _this.initPageNum();
            if(arg.callback){
                arg.callback(_this.currNum);
            }
        });
    };
    this.init();
    //绑定事件
    //首页
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
    //上一页
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
    //下一页
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
    //末页
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
