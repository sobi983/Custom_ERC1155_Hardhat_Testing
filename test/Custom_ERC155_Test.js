const {time,loadFixture,} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Custom ERC1155", function () {
let hardhatToken
let owner
it("Ddeployment of the contract", async()=>{

  [owner] = await ethers.getSigners();
  const Token = await ethers.getContractFactory("Exhibition");

  hardhatToken = await Token.deploy("");
  hardhatToken.deployed()
})

it("Checking the gas price for saving the data ", async()=>{
  await hardhatToken.saveTokens_Quantity_Prices(['1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20'],['10','11','12','13','15','16','10','9','67','29','12','14','67','77','3','5','77','8','9','9'],['1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20'])
  await hardhatToken.mintBatch(owner.address,['1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20'],['10','11','12','13','15','16','10','9','67','29','12','14','67','77','3','5','77','8','9','9'],'0x')
})


  


});
