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



contract BDGMPublicSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public oriToken;
    IERC20 public rewardToken;

    uint256 public joinIdoPrice;
    uint256 public stakeAmount;
    uint256 public rewardAmount;

    bool public mbStart=false;
    bool public mbWhiteAddr=false;
    uint256 public startTime=0;
    uint256 public mDt=0;
    uint256[4] public mChaimDtArr = [0,0,0,0];
    uint256[4] public mChaimCoeArr = [50,17,17,16];//%

    mapping (address => uint256) private _balance;
    uint256 private _addrAmount=0;
    uint256 private _sumAmount=0;

    mapping (address => bool) private _Is_WhiteAddrArr;
    mapping (address => uint256) private _alreadyChaimNumArr;
    mapping (address => bool) private _bClaimBTC;
    address[] private _WhiteAddrArr;
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
        joinIdoPrice=639000000000;
        stakeAmount=12780000000000000000;
        rewardAmount=20000000000000000000000000;

        mDt = 39*3600;
        mChaimDtArr[0]= mDt + 3*3600;
        mChaimDtArr[1]= mChaimDtArr[0] + 30*24*3600;
        mChaimDtArr[2]= mChaimDtArr[0] + 60*24*3600;
        mChaimDtArr[3]= mChaimDtArr[0] + 90*24*3600;

        oriToken = IERC20(0xDb3AC6CDf8D83Fca81338C2E0EE063dB5744036c);
        rewardToken = IERC20(0xd8bcAF3e57C3D731B4A4a26bcC3BD85E074C9233);
        mFundAddress = 0x2EDDE6f6ec946CAbF1DC356cB88dE7589486B852;
    }
    
    /* ========== VIEWS ========== */
    function sumCount() external view returns(uint256){
        return _sumCount;
    }
    function sumAmount() external view returns(uint256){
        return _sumAmount;
    }
    function addrAmount() external view returns(uint256){
        return _addrAmount;
    }
    function balanceof(address account) external view returns(uint256){
        return _balance[account];
    }
    function claimTokenNum(address account) external view returns(uint256){
        return _alreadyChaimNumArr[account];
    }
    function bClaimBTC(address account) external view returns(bool){
        return _bClaimBTC[account];
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
        require(iD <= _sumCount, "BDGMPublicSale: exist num!");
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
        require(toId <= _sumCount, "BDGMPublicSale: exist num!");
        require(fromId <= toId, "BDGMPublicSale: exist num!");
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
        return _Is_WhiteAddrArr[account];
    }

    function getWhiteAccountNum() public view returns (uint256){
        return _WhiteAddrArr.length;
    }

    function getWhiteAccountIth(uint256 ith) public view returns (address WhiteAddress){
        require(ith <_WhiteAddrArr.length, "BDGMPublicSale: not in White Adress");
        return _WhiteAddrArr[ith];
    }
    function getExpectedAmount(address account) public view returns (uint256){
        uint256 ExpectedAmount = _balance[account];
        if(ExpectedAmount==0)return ExpectedAmount;
        if(_sumAmount>stakeAmount){
            ExpectedAmount = stakeAmount.mul(ExpectedAmount).div(_sumAmount);
        }
        return ExpectedAmount;
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
        uint256[] memory paraList = new uint256[](uint256(23));
        paraList[0]=0; if(mbStart && block.timestamp>startTime) paraList[0]=1;
        paraList[1]=startTime;//start Time
        paraList[2]=startTime+mDt;//end Time
        paraList[3]=joinIdoPrice;//Token Price: 
        paraList[4]=stakeAmount;//max buy Amount
        paraList[5]=rewardAmount;//max reward Amount
        paraList[6]=_addrAmount;//Total Participants
        paraList[7]=_sumAmount;//Total Committed
        paraList[8]=_balance[account];//You committed
        uint256 expectedAmount = getExpectedAmount(account);
        uint256 refundAmount = _balance[account].sub(expectedAmount);
        expectedAmount = expectedAmount.mul(10**18).div(joinIdoPrice);
        paraList[9]=expectedAmount;//Expected token Amount
        paraList[10]=refundAmount;//refund Amount
        paraList[11]=_alreadyChaimNumArr[account]; //Claim num
        paraList[12]=0; if(_bClaimBTC[account]) paraList[12]=1;//is Claim BTC

        uint256 coe=getClaimCoe(account);
        paraList[13]=coe;//can claim ratio
        paraList[14]=expectedAmount.mul(coe).div(100);//can claim amount
        uint256 LastCoe=getLastClaimCoe(account);
        paraList[15]=LastCoe;//last claim ratio
        paraList[16]=expectedAmount.mul(LastCoe).div(100);//last claim amount

        paraList[17]=startTime+mChaimDtArr[0];
        paraList[18]=startTime+mChaimDtArr[1];
        paraList[19]=startTime+mChaimDtArr[2];
        paraList[20]=startTime+mChaimDtArr[3];
        return paraList;
    }
    //---write---//
    //join Ido
    function joinIdo(uint256 amount) external nonReentrant {
        require(mbStart && block.timestamp>startTime, "BDGMPublicSale: not Start!");
        require(block.timestamp<startTime+mDt, "BDGMPublicSale: already end!");
        if(mbWhiteAddr)require(_Is_WhiteAddrArr[_msgSender()], "BDGMPublicSale:Account  not in white list");
        require(10**8 <=amount, "BDGMPublicSale:amount is too small");
    
        oriToken.safeTransferFrom(_msgSender(),address(this), amount);

        if(_balance[_msgSender()]==0){
            _addrAmount = _addrAmount+1;
        }
        _balance[_msgSender()] = _balance[_msgSender()].add(amount);
        _sumAmount = _sumAmount.add(amount);

        _sumCount = _sumCount.add(1);
        _joinIdoPropertys[_sumCount].addr = _msgSender();
        _joinIdoPropertys[_sumCount].joinIdoAmount = amount;
        _joinIdoPropertys[_sumCount].time = block.timestamp;

        emit JoinIdoCoins(msg.sender, amount, _sumCount);
    }
    //claim Token
    function claimToken() external nonReentrant{
        require(mbStart && block.timestamp>startTime, "BDGMPublicSale: not Start!");
        require(block.timestamp>startTime+mDt, "BDGMPublicSale: need end!");
         if(mbWhiteAddr)require(_Is_WhiteAddrArr[_msgSender()], "BDGMPublicSale:Account  not in white list");
        require(_balance[_msgSender()]>0, "BDGMPublicSale:balance zero");
        require(block.timestamp>startTime+mChaimDtArr[0], "BDGMPublicSale: need begin claim!");
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
        require(coe>0, "BDGMPublicSale: claim 0!");

        uint256 expectedAmount = getExpectedAmount(_msgSender());
        expectedAmount = expectedAmount.mul(coe).div(100);

        expectedAmount = expectedAmount.mul(10**18).div(joinIdoPrice);
        if(expectedAmount>0)rewardToken.safeTransfer( _msgSender(),expectedAmount);
    }
    //claim btc
    function claimBTC() external nonReentrant{
        require(mbStart && block.timestamp>startTime, "BDGMPublicSale: not Start!");
        require(block.timestamp>startTime+mDt, "BDGMPublicSale: need end!");
         if(mbWhiteAddr)require(_Is_WhiteAddrArr[_msgSender()], "BDGMPublicSale:Account  not in white list");
        require(_balance[_msgSender()]>0, "BDGMPublicSale:balance zero");
        require(!_bClaimBTC[_msgSender()], "BDGMPublicSale:already claim btc");

        uint256 expectedAmount = getExpectedAmount(_msgSender());
        uint256 refundAmount = _balance[_msgSender()].sub(expectedAmount);
        _bClaimBTC[_msgSender()]=true;
        if(refundAmount>0) oriToken.safeTransfer( _msgSender(),refundAmount);
    }
    
    //---write onlyOwner---//
   function setParameters(address oriTokenAddr,address rewardTokenAddr,
                          uint256 joinIdoPrice0,uint256 stakeAmount0,uint256 rewardAmount0
   ) external onlyOwner {
        require(!mbStart, "BDGMPublicSale: already Start!");
        oriToken = IERC20(oriTokenAddr);
        rewardToken = IERC20(rewardTokenAddr);

        joinIdoPrice=joinIdoPrice0;
        stakeAmount=stakeAmount0;
        rewardAmount=rewardAmount0;
    }
    function setStart(bool bstart,uint256 tTimetamp) external onlyOwner{
        mbStart = bstart;
        startTime = tTimetamp;
    }
    function setDt(uint256 tDt,uint256[] calldata  dtArr) external onlyOwner{
        mDt = tDt;
        for (uint256 i = 0; i < mChaimDtArr.length; i++){
            mChaimDtArr[i]=dtArr[i];
        }
    }
    function setbWhiteAddr(bool bWhiteAddr) external onlyOwner{
        require(!mbStart, "BDGMPublicSale: already Start!");
        mbWhiteAddr = bWhiteAddr;
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

    function addWhiteAccount(address account) external onlyOwner{
        require(!_Is_WhiteAddrArr[account], "BDGMPublicSale:Account is already in White list");
        _Is_WhiteAddrArr[account] = true;
        _WhiteAddrArr.push(account);
    }
    function addWhiteAccount(address[] calldata  accountArr) external onlyOwner{
        for(uint256 i=0; i<accountArr.length; ++i) {
            require(!_Is_WhiteAddrArr[accountArr[i]], "BDGMPublicSale:Account is already in White list");
            _Is_WhiteAddrArr[accountArr[i]] = true;
            _WhiteAddrArr.push(accountArr[i]);     
        }
    }
    function removeWhiteAccount(address account) external onlyOwner{
        require(_Is_WhiteAddrArr[account], "BDGMPublicSale:Account is already out White list");
        for (uint256 i = 0; i < _WhiteAddrArr.length; i++){
            if (_WhiteAddrArr[i] == account){
                _WhiteAddrArr[i] = _WhiteAddrArr[_WhiteAddrArr.length - 1];
                _WhiteAddrArr.pop();
                _Is_WhiteAddrArr[account] = false;
                break;
            }
        }
    }


    
}