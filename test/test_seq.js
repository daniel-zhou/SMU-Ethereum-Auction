const Dice = artifacts.require("Dice");
const DiceBattle = artifacts.require("DiceBattle");
const DiceToken = artifacts.require("DiceToken");
const DiceMarket = artifacts.require("DiceMarket");


contract("Dice", accounts => {
  let dice;
  let diceBattle;
  let token;
  let diceMarket;
  const platform = accounts[0];
  const user1 = accounts[1];
  const user2 = accounts[2];
  const user3 = accounts[3];
  const user4 = accounts[4];
  let startingBal = 2000;
  let fee = 100;
  let listPrice = 500;

  it("Create dices", () => {
      Dice.deployed()   //deployed using account[0]
      .then(_inst => {
        dice = _inst;
                        //add a dice
        return dice.add(6,1,{from: user1, value: 100000000000000000});
      }).then(() => {
        return dice.add(6,1,{from: user2, value: 100000000000000000});
      }).then(() => {
        return dice.ownerOf(0);
      }).then((owner) => {
        assert.equal(owner, user1); //assert that dice0 is owned by user1
      }).then(() => {
        return dice.ownerOf(1);
      }).then((owner) => {
        assert.equal(owner, user2); //assert that dice1 is owned by user2
      })
  });

  it("roll a dice", () =>
        dice.roll(0, {from: user1})
      .then((rsl) => {
                                    //assert "rolling" event emitted
        assert.equal(rsl.logs[0].event, "rolling", "Rolling event should be emitted");
        return dice.stopRoll(0, {from: user1});
      }).then((rsl) => {
                                    //assert "rolled" event emitted
        assert((rsl.logs[0].event == "rolled") ||
               (rsl.logs[1].event == "rolled"), "Rolled event should be emitted");
      })
  );

  it("battle 2 dices", () =>
      DiceBattle.deployed()   //deployed using account[0]
      .then(_inst => {
        diceBattle = _inst;
                              //approve() to diceBattle before list()
        return dice.approve(diceBattle.address, 0, {from: user1});
      }).then(() => {
                              //list() on diceBattle
        return diceBattle.list(0, {from: user1});
      }).then(() => {
        return dice.approve(diceBattle.address, 1, {from: user2});
      }).then(() => {
        return diceBattle.list(1, {from: user2});
      }).then(() => {
        return diceBattle.battle(0, 1, {from: user1});
      }).then((rsl) => {
                              //show battle results
        console.log("      Battle results:" + rsl.logs[0].event);
        return dice.getDiceNumber(0);
      }).then((rsl) => {
        console.log("      Dice 0 value:" + rsl.toNumber());
        return dice.getDiceNumber(1);
      }).then((rsl) => {
        console.log("      Dice 1 value:" + rsl.toNumber());
        return dice.ownerOf(0);
      }).then((rsl) => {
        console.log("      Dice 0 owner:" + rsl);
        return dice.ownerOf(1);
      }).then((rsl) => {
        console.log("      Dice 1 owner:" + rsl);

      })
  );


  it("Create 1 more dice for user3 and list it", () =>
      dice.add(6,1,{from: user3, value: 100000000000000000})
    .then((_rsl) => {
      return DiceMarket.deployed()
    }).then((_inst) => {
      diceMarket = _inst;
                              //approve() to diceMarket before list()
      return dice.approve(diceMarket.address, 2, {from: user3});
    }).then(() => {
                              //list() on diceMarket
      return diceMarket.list(2, listPrice, {from: user3});
    }).then(() => {
      return dice.ownerOf.call(2);
    }).then((rsl) => {
      assert.equal(rsl.valueOf(), diceMarket.address);  //assert ownership has changed
    })
  );

  it("mint "+startingBal+" tokens to user4", () =>
      DiceToken.deployed()
      .then((_inst) => {
        token = _inst;
        return token.mint(user4, startingBal);
      }).then(() => {
        return token.balanceOf.call(user4);
      }).then((rsl) => {
        assert.equal(rsl.valueOf(), startingBal);   //assert token minted to user4
      })
  );

  it("user4 buys dice2 from user3 via the dicemarket", () =>
      token.approve(diceMarket.address, listPrice + fee, {from: user4})
      .then(() => {
        return diceMarket.buy(2, listPrice + fee, {from: user4});   //user4 buys dice
      }).then(() => {
        return dice.ownerOf.call(2);
      }).then((rsl) => {
        assert.equal(rsl.valueOf(), user4);   //assert ownership changed
        return token.balanceOf.call(user4);
      }).then((rsl) => {
        assert.equal(rsl.valueOf(), startingBal - listPrice - fee);   //assert right token balance deducted
      })
  )
});
