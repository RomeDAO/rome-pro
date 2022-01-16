// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

/* ========== FORGE DEPENDENDCIES ========== */
import "../../lib/ds-test/src/test.sol";
import "./utils/Vm.sol";

/* ========== INTERFACES ========== */
import "./interfaces/IERC20.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IBond.sol";

/* ========== CONTRACT DEPENDENCIES ========== */
import "@openzeppelin/contracts/math/SafeMath.sol";
import {RomeProFactory, CustomBond, CustomTreasury} from "../factory.sol";
import {RomeProFactoryStorage} from "../factoryStorage.sol";
import {RPSubsidyRouter} from "../subsidy.sol";

/* ========== BOND CONTRACT ========== */
contract BondUser {
    using SafeMath for uint;
    
    function approve(address _token, address _who, uint _amount) public {
        IERC20( _token ).approve(_who, _amount);
    }

    function deposit(address _bond, uint _amount, uint maxPrice, address depositor) public returns(uint) {
        uint val = IBond(_bond).deposit(_amount, maxPrice, depositor);
        return val;
    }

    function addLiquidity(address router,address tokenA, address tokenB) public {
        uint amountA = IERC20(tokenA).balanceOf(address(this));
        uint amountB = IERC20(tokenB).balanceOf(address(this));
        IERC20(tokenA).approve(router,amountA);
        IERC20(tokenB).approve(router,amountB);
        IRouter(router).addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}

contract BondTest is DSTest {
    using SafeMath for uint;

    Vm internal constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    /* ========== USER INPUTS ========= */
    IERC20 internal PAYOUT = IERC20(0x10010078a54396F62c96dF8532dc2B4847d47ED3); // HND token

    IUniswapV2Pair internal PRINCIPLE = IUniswapV2Pair(0xdF1d4C921Fe6a04eF086b4191E8742eCfbDAa355); // HND/MOVR liquidity

    IRouter internal ROUTER = IRouter(0xAA30eF758139ae4a7f798112902Bf6d65612045f);

    address internal initialOwner = (0x10010078a54396F62c96dF8532dc2B4847d47ED3); // HND Multisig

    /* ========== MOVR DEPENDENCIES ========== */
    IERC20 internal WMOVR = IERC20(0x98878B06940aE243284CA214f92Bb71a2b032B8A);

    AggregatorV3Interface internal FEED = AggregatorV3Interface(0x3f8BFbDc1e79777511c00Ad8591cef888C2113C1);

    /* ========== TESTING STATE ========== */

    RomeProFactory internal factory;

    RomeProFactoryStorage internal factoryStorage;

    RPSubsidyRouter internal subsidy;

    uint movrPrice;

    address internal BOND;

    address internal TREASURY;

    uint numberUsers = 10;

    BondUser[] internal user;

    function setUp() public virtual {

    emit log("|==================== USER INPUTS ====================|");
    emit log_named_address("Payout Token =", address(PAYOUT));
    emit log_named_address("Principle Token =", address(PRINCIPLE));
    emit log_named_address("Router", address(ROUTER));
    emit log("|=====================================================|");

        
        //1. Deploy Factory Storage and subsidy
        factoryStorage = new RomeProFactoryStorage();

        subsidy = new RPSubsidyRouter();

        //2. Deploy Factory
        factory = new RomeProFactory(
            address(1), // Rome Dao Treasury
            address(factoryStorage),
            address(subsidy),
            address(this) // Rome Dao Access control
        );

        factoryStorage.setFactoryAddress(address(factory));

        uint[] memory _tierCeilings = new uint[](1);
        _tierCeilings[0] = 10*1e18;
        uint[] memory _fees = new uint[](1);
        _fees[0] = 33300;

        //3. CreateBond and Treasury
        (TREASURY, BOND) = factory.createBondAndTreasury(
            address(PAYOUT),
            address(PRINCIPLE),
            initialOwner,
            _tierCeilings,
            _fees
        );

        movrPrice = uint(FEED.latestAnswer()); // Store Movr price in 8 decimals.
        emit log_named_uint("<MOVR Price USD> ==", movrPrice.div(1e8));

        for (uint i = 0; i < numberUsers; i++) {
            user.push( new BondUser() );
            user[i].approve(address(PRINCIPLE), address(BOND), type(uint256).max);
        }

    }

    function testDeployment() public {
        //1. set terms
        emit log("|==================== BOND TERMS ====================|");
        uint bcv = 6000;
        emit log_named_uint("<|BCV|> == ", bcv);
        uint vestingTerm = 32000;
        emit log_named_uint("<|Vesting Term in blocks|>", vestingTerm);
        uint minPrice = 29040;
        emit log_named_uint("<|Min Price|> ==", minPrice);
        uint maxPayout = 5;
        emit log_named_uint("<|Max Payout|> ==", maxPayout);

        vm.startPrank(initialOwner);
        IBond(BOND).setBondTerms(IBond.PARAMETER(0),vestingTerm);
        IBond(BOND).initializeBond(
            bcv,
            vestingTerm,
            minPrice,
            maxPayout,
            5000000000000000,
            1
        );
        vm.stopPrank();

        //2. Prints HND Price       
        (uint reserve0, uint reserve1,) = PRINCIPLE.getReserves();
        uint tokenPrice = reserve1.mul(movrPrice).div(reserve0);
        emit log_named_uint("<|HND Price USD|> ==", tokenPrice.div(1e8));

        for (uint i = 0; i < numberUsers; i++) {
            emit log_named_uint("deposit number",i+1);
            emit log_named_uint("bond price ", BOND.bondPrice());
            emit log_named_uint("bond price in USD", BOND.bondPriceInUSD().div(1e18));
            address addr = address(user[i]);

            //4. mint Rome and Movr
            setBalance(addr,50*1e18,address(WMOVR),3);
            setBalance(addr,25*1e9,address(ROME),0);     

            //5. add liquidity
            uint balBefore = ROME.balanceOf(addr);
            user[i].addLiquidity(address(ROUTER),address(ROME),address(WMOVR));
            emit log_named_uint("LP added in ROME", 2*(balBefore.sub(ROME.balanceOf(addr))).div(1e9));

            //6. purchase bonds
            uint payout = user[i].deposit(ROMEMOVR.balanceOf(addr), 200000*1e11, addr);

            //7. Print Payout in USD
            emit log_named_uint("Payout in ROME ==",payout.div(1e9));

            emit log("==============================");


        }
    }

    // /* ========== HELPERS ========== */
    // function setBalance(address account, uint256 amount, address token, uint256 slot) public {
    //     hevm.store(
    //         token,
    //         keccak256(abi.encode(account, slot)),
    //         bytes32(amount)
    //     );
    // }

    // function setVault(address tar, address vault) public {
    //     hevm.store(
    //         tar,
    //         bytes32(uint(5)),
    //         bytes32(uint256(uint160(vault)))                         
    //     );
    // }

}
