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
import "./interfaces/ITreasury.sol";

/* ========== CONTRACT DEPENDENCIES ========== */
import "@openzeppelin/contracts/math/SafeMath.sol";
import {RomeProFactory, CustomBond, CustomTreasury} from "../contracts/factory.sol";
import {RomeProFactoryStorage} from "../contracts/factoryStorage.sol";
import {RPSubsidyRouter} from "../contracts/subsidy.sol";
import {GenericBondingCalculator} from "../contracts/genericBondingCalculator.sol";

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

    address internal initialOwner = (0xBf3bD01bd5fB28d2381d41A8eF779E6aa6f0a811); // HND Multisig

    IBond internal customBond = IBond(0x88D4768e986dC1FCda7C6e7E5E70f4457efd1fE9);

    /* ========== MOVR DEPENDENCIES ========== */
    IERC20 internal WMOVR = IERC20(0x98878B06940aE243284CA214f92Bb71a2b032B8A);

    AggregatorV3Interface internal FEED = AggregatorV3Interface(0x3f8BFbDc1e79777511c00Ad8591cef888C2113C1);

    /* ========== TESTING STATE ========== */

    RomeProFactory internal factory;

    RomeProFactoryStorage internal factoryStorage;

    RPSubsidyRouter internal subsidy;
    
    GenericBondingCalculator internal calculator;

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

        
        //1. Deploy Factory Storage and subsidy and calculator
        factoryStorage = new RomeProFactoryStorage();

        subsidy = new RPSubsidyRouter();

        calculator = new GenericBondingCalculator();

        //2. Deploy Factory
        factory = new RomeProFactory(
            address(1), // Rome Dao Treasury
            address(factoryStorage),
            address(subsidy),
            address(this) // Rome Dao Access control
        );

        factoryStorage.setFactoryAddress(address(factory));

        uint[] memory _tierCeilings = new uint[](1);
        _tierCeilings[0] = 1000000*1e18;
        uint[] memory _fees = new uint[](1);
        _fees[0] = 33300; //change to 33,300/1,000,000

        //3. CreateBond and Treasury
        (TREASURY, BOND) = factory.createBondAndTreasury(
            address(PAYOUT),
            address(PRINCIPLE),
            initialOwner,
            _tierCeilings,
            _fees
        );

        setBalance(TREASURY, 100000 * 1e18, address(PAYOUT), 2);

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
        uint bcv = 10000;
        emit log_named_uint("<|BCV|> == ", bcv);
        uint vestingTerm = 32000;
        emit log_named_uint("<|Vesting Term in blocks|>", vestingTerm);
        uint minPrice = 715475;
        emit log_named_uint("<|Min Price|> ==", minPrice);
        uint maxPayout = 5;
        emit log_named_uint("<|Max Payout|> ==", maxPayout);
        uint initialDebt = 0;
        // uint initialDebt = IBond(customBond).totalDebt();
        emit log_named_uint("<|Initial Debt|> ==", initialDebt);

        vm.startPrank(initialOwner);
        IBond(BOND).setBondTerms(IBond.PARAMETER(0),vestingTerm);
        IBond(BOND).initializeBond(
            bcv,
            vestingTerm,
            minPrice,
            maxPayout,
            100000000000000000000000000,
            initialDebt
        );
        ITreasury(TREASURY).toggleBondContract(BOND);
        vm.stopPrank();

        //2. Prints HND Price       
        (uint reserve0, uint reserve1,) = PRINCIPLE.getReserves();
        uint tokenPrice = reserve1.mul(movrPrice).div(reserve0);
        emit log_named_uint("<|HND Price USD (4)|> ==", tokenPrice.div(1e4));

        emit log_named_uint("<|bondPrice at 0 discount|>", tokenPrice.mul(1e17).div(calculator.valuationInUSD(address(PRINCIPLE),address(WMOVR),address(FEED))));

        emit log_named_uint("<| Valuation Per Principle Token MOVR (6) |>", calculator.valuation(address(PRINCIPLE),address(WMOVR)).div(1e12));
        emit log_named_uint("<| Valuation Per Principle Token HND (alpha) (6) |>", calculator.valuation(address(PRINCIPLE),address(PAYOUT)).div(1e12));
        emit log_named_uint("<| Valuation Per Principle Token USD (6) |>", calculator.valuationInUSD(address(PRINCIPLE),address(WMOVR),address(FEED)).div(1e12));
        emit log("|===================================================|");

        //3. Users Bond
        uint totalBonded;
        for (uint i = 0; i < numberUsers; i++) {
            emit log_named_uint("deposit number",i+1);
            emit log_named_uint("tot debt (2)", IBond(BOND).totalDebt().div(1e16));
            uint _bondPrice = IBond(BOND).bondPrice();
            emit log_named_uint("bond price (7)", _bondPrice);

            uint _trueBondPrice = IBond(BOND).trueBondPrice();
            emit log_named_uint("true bond price (7)", _trueBondPrice);
            emit log_named_uint("true bond price in USD (4)", bondPriceInUSD(_trueBondPrice).div(1e14));
            address addr = address(user[i]);

            // //4. mint token and Movr for LP
            setBalance(addr,1000*1e18,address(WMOVR),3);
            setBalance(addr,1000*1e18,address(PAYOUT),2);     

            //5. add liquidity
            uint balBefore = PAYOUT.balanceOf(addr);
            user[i].addLiquidity(address(ROUTER),address(PAYOUT),address(WMOVR));
            uint deposited = 2*(balBefore.sub(PAYOUT.balanceOf(addr)));
            emit log_named_uint("LP added in PAYOUT (4) ==", deposited.div(1e14));

            //6. purchase bonds
            uint payout = user[i].deposit(address(BOND),PRINCIPLE.balanceOf(addr), 200000*1e11, addr);
            emit log_named_uint("Payout in HND (4) ==",payout.div(1e14));

            // //7. Print Payout in USD
            uint fee = payout.mul( IBond(BOND).currentRomeFee() ).div( 1e6 );
            payout = payout.sub(fee);
            emit log_named_uint("True Payout in HND (4) ==",payout.div(1e14));
            totalBonded = totalBonded.add(payout);
            emit log_named_uint("==============================Total Bonded (2)", totalBonded.div(1e16));
        }
    }

    /* ========== HELPERS ========== */

    function bondPriceInUSD(uint256 bondPrice) public view returns ( uint price_ ) {
       price_ = bondPrice
                .mul( calculator.valuationInUSD(address(PRINCIPLE), address(WMOVR), address(FEED)) )
                .div(1e7);
    }
    function setBalance(address account, uint256 amount, address token, uint256 slot) public {
        vm.store(
            token,
            keccak256(abi.encode(account, slot)),
            bytes32(amount)
        );
    }
}