// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10 <0.8.19;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}



contract BDGMIDO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public rewardToken;

    uint256 public joinIdoPrice;
    uint256 public rewardAmount;
    uint256 private _MaxCount;

    bool public mbStart=false;
    uint256 public startTime=0;
    uint256 public mDt=0; 
    uint256[4] public mChaimDtArr = [0,0,0,0];
    uint256[4] public mChaimCoeArr = [50,17,17,16];//%
    
    mapping (address => bool) public mbWhiteArr1;
    uint256 public mWhiteArr1Num=0;

    mapping (address => bool) private _bAlreadyJoinIdoArr;
    mapping (address => uint256) private _alreadyChaimNumArr;

    struct sJoinIdoPropertys {
        address addr;
        uint256 joinIdoAmount;
        uint256 time;
    }
    mapping(uint256 => sJoinIdoPropertys) private _joinIdoPropertys;
    uint256 private _sumCount;

    event JoinIdoCoins(address indexed user, uint256 amount,uint256 id);
    address public mFundAddress;

    constructor(){
        joinIdoPrice=2857000000000000;
        _MaxCount=500;
        rewardAmount=5000000000000000000000;

        mDt = 39*3600;
        mChaimDtArr[0]= mDt + 3*3600;
        mChaimDtArr[1]= mChaimDtArr[0] + 30*24*3600;
        mChaimDtArr[2]= mChaimDtArr[0] + 60*24*3600;
        mChaimDtArr[3]= mChaimDtArr[0] + 90*24*3600;

        rewardToken = IERC20(0xd8bcAF3e57C3D731B4A4a26bcC3BD85E074C9233);
        mFundAddress = 0x2EDDE6f6ec946CAbF1DC356cB88dE7589486B852;
    }
    
    /* ========== VIEWS ========== */
    function maxCount() external view returns(uint256){
        return _MaxCount;
    }
    function sumCount() external view returns(uint256){
        return _sumCount;
    }
    function isAlreadyEnd() external view returns(bool){
        if(!mbStart) return false;
        if( block.timestamp<startTime) return false;
        if(block.timestamp<startTime+mDt) return false;
        return true;
    }
    function getNowTIme() external view returns(uint256){
        return block.timestamp;
    }
    //read info
    function joinIdoInfo(uint256 iD) external view returns (
        address addr,
        uint256 joinIdoAmount,
        uint256 time
        ) {
        require(iD <= _sumCount, "BDGMIDO: exist num!");
        addr = _joinIdoPropertys[iD].addr;
        joinIdoAmount = _joinIdoPropertys[iD].joinIdoAmount;
        time = _joinIdoPropertys[iD].time;
        return (addr,joinIdoAmount,time);
    }

    function joinIdoInfos(uint256 fromId,uint256 toId) external view returns (
        address[] memory addrArr,
        uint256[] memory joinIdoAmountArr,
        uint256[] memory timeArr
        ) {
        require(toId <= _sumCount, "BDGMIDO: exist num!");
        require(fromId <= toId, "BDGMIDO: exist num!");
        addrArr = new address[](toId-fromId+1);
        joinIdoAmountArr = new uint256[](toId-fromId+1);
        timeArr = new uint256[](toId-fromId+1);
        uint256 i=0;
        for(uint256 ith=fromId; ith<=toId; ith++) {
            addrArr[i] = _joinIdoPropertys[ith].addr;
            joinIdoAmountArr[i] = _joinIdoPropertys[ith].joinIdoAmount;
            timeArr[i] = _joinIdoPropertys[ith].time;
            i = i+1;
        }
        return (addrArr,joinIdoAmountArr,timeArr);
    }
    
    function isWhiteAddr(address account) public view returns (bool) {
        return mbWhiteArr1[account];
    }
    function isAlreadyJoinIdoAddr(address account) public view returns (bool) {
        return _bAlreadyJoinIdoArr[account];
    }
    function alreadyChaimNum(address account) public view returns (uint256) {
        return _alreadyChaimNumArr[account];
    }
    function getWhiteAccountNum() public view returns (uint256){
        return mWhiteArr1Num;
    }
    function getClaimCoe(address account) public view returns (uint256){
        uint256 coe=0;
        for (uint256 i = 0; i < mChaimDtArr.length; i++){
            if(block.timestamp>startTime+mChaimDtArr[i]){
                if(_alreadyChaimNumArr[account]<i+1)coe =coe+ mChaimCoeArr[i];
            }
            else{
                break;
            }
        }
        return coe;
    }
    function getLastClaimCoe(address account) public view returns (uint256){
        uint256 coe=0;
        for (uint256 i = 0; i < mChaimDtArr.length; i++){
            if(_alreadyChaimNumArr[account]<i+1) coe =coe+ mChaimCoeArr[i];
        }
        return coe;
    }
    function getParameters(address account) public view returns (uint256[] memory){
        uint256[] memory paraList = new uint256[](uint256(19));
        paraList[0]=0; if(mbStart&& block.timestamp>startTime) paraList[0]=1;
        paraList[1]=startTime;
        paraList[2]=0; if(mbWhiteArr1[account]) paraList[2]=1;
        paraList[3]=0; if(_bAlreadyJoinIdoArr[account]) paraList[3]=1;

        uint256 coe=getClaimCoe(account);
        paraList[4]=coe;//can claim ratio
        paraList[5]=rewardAmount.mul(coe).div(100);//can claim amount

        uint256 LastCoe=getLastClaimCoe(account);
        paraList[6]=LastCoe;//last claim ratio
        paraList[7]=rewardAmount.mul(LastCoe).div(100);//last claim amount
        paraList[8]=startTime+mDt;//end time
        paraList[9]=rewardAmount;//sum rewardAmount
        paraList[10]=_MaxCount;
        paraList[11]=_sumCount;
        paraList[12]=mWhiteArr1Num;
        paraList[13]=startTime+mChaimDtArr[0];
        paraList[14]=startTime+mChaimDtArr[1];
        paraList[15]=startTime+mChaimDtArr[2];
        paraList[16]=startTime+mChaimDtArr[3];
        return paraList;
    }

    //---write---//
    function joinIdo() external payable nonReentrant {
        require(mbStart&& block.timestamp>startTime, "BDGMIDO: not Start!");
        require(block.timestamp<startTime+mDt, "BDGMIDO: already end!");
        require(_sumCount<_MaxCount, "BDGMIDO: already end!");
        require(mbWhiteArr1[_msgSender()], "BDGMIDO:Account  not in white list");
        require(!_bAlreadyJoinIdoArr[_msgSender()], "BDGMIDO: already joinIdo!");
        require(joinIdoPrice <= msg.value, "BDGMIDO:value sent is not correct");
    
        if(msg.value>joinIdoPrice){
            payable(_msgSender()).transfer(msg.value.sub(joinIdoPrice));
        }

        _bAlreadyJoinIdoArr[_msgSender()]=true;

        _sumCount = _sumCount.add(1);
        _joinIdoPropertys[_sumCount].addr = _msgSender();
        _joinIdoPropertys[_sumCount].joinIdoAmount = joinIdoPrice;
        _joinIdoPropertys[_sumCount].time = block.timestamp;

        emit JoinIdoCoins(msg.sender, joinIdoPrice, _sumCount);
    }

    function claimToken() external nonReentrant{
        require(mbStart && block.timestamp>startTime, "BDGMIDO: not Start!");
        require(block.timestamp>startTime+mDt, "BDGMIDO: need ido end!");
        require(mbWhiteArr1[_msgSender()], "BDGMIDO:Account  not in white list");
        require(_bAlreadyJoinIdoArr[_msgSender()], "BDGMIDO: not joinIdo!");
        require(block.timestamp>startTime+mChaimDtArr[0], "BDGMIDO: need begin claim!");
        require(_alreadyChaimNumArr[_msgSender()]<mChaimDtArr.length, "BDGMPublicSale: already claim all!");

       uint256 coe=0;
        for (uint256 i = 0; i < mChaimDtArr.length; i++){
            if(block.timestamp>startTime+mChaimDtArr[i]){
                if(_alreadyChaimNumArr[_msgSender()]<i+1){
                    coe =coe+ mChaimCoeArr[i];
                    _alreadyChaimNumArr[_msgSender()]=_alreadyChaimNumArr[_msgSender()]+1;
                }  
            }
            else{
                break;
            }
        }

        require(coe>0, "BDGMIDO: claim 0!");
        uint256 amount = rewardAmount.mul(coe).div(100);
        rewardToken.safeTransfer(_msgSender(), amount);
    }
    //---write onlyOwner---//
   function setParameters(address rewardTokenAddr,
                          uint256 joinIdoPrice0,uint256 maxCount0,uint256 rewardAmount0
   ) external onlyOwner {
        require(!mbStart, "BDGMIDO: already Start!");
        rewardToken = IERC20(rewardTokenAddr);
        joinIdoPrice=joinIdoPrice0;
        _MaxCount=maxCount0;
        rewardAmount=rewardAmount0;
    }
    function setStartAlpha(bool bstart,uint256 tTimetamp) external onlyOwner{
        mbStart = bstart;
        startTime = tTimetamp;
    }

    function setDt(uint256 tDt,uint256[] calldata  dtArr) external onlyOwner{
        mDt = tDt;
        for (uint256 i = 0; i < mChaimDtArr.length; i++){
            mChaimDtArr[i]=dtArr[i];
        }
    }
    

    receive() external payable {}
    function withdraw(uint256 amount) external onlyOwner{
        (bool success, ) = payable(mFundAddress).call{value: amount}("");
        require(success, "Low-level call failed");
    }
    function withdrawToken(address tokenAddr,uint256 amount) external onlyOwner{ 
        IERC20 token = IERC20(tokenAddr);
        token.safeTransfer(mFundAddress, amount);
    }

    function addWhiteAddr1(address account) external onlyOwner{
        require(!mbWhiteArr1[account], "Account is already White list");
        mbWhiteArr1[account] = true;
        mWhiteArr1Num=mWhiteArr1Num+1;
    }
    function addWhiteAccount1(address[] calldata  accountArr) external onlyOwner{
        for(uint256 i=0; i<accountArr.length; ++i) {
            require(!mbWhiteArr1[accountArr[i]], "Account is already White list");
            mbWhiteArr1[accountArr[i]] = true;   
        }
        mWhiteArr1Num=mWhiteArr1Num+accountArr.length;
    }
    function removeWhiteAccount1(address account) external onlyOwner{
        require(mbWhiteArr1[account], "Account is already out White list");
        mbWhiteArr1[account] = false;
        mWhiteArr1Num=mWhiteArr1Num.sub(1);
    }


    
}