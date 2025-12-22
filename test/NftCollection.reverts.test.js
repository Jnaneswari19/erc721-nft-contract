const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NftCollection reverts & pause", function () {
  let NftCollection, nft, owner, addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    NftCollection = await ethers.getContractFactory("NftCollection");
    nft = await NftCollection.deploy("MyNFT", "MNFT", 2); // maxSupply = 2 for testing
    await nft.waitForDeployment(); // ethers v6 requires this
  });

  it("reverts minting to zero address", async function () {
    const ZERO = "0x0000000000000000000000000000000000000000";
    await expect(nft.mint(ZERO, 1, "uri"))
      .to.be.revertedWith("Cannot mint to zero address");
  });

  it("reverts duplicate token ID", async function () {
    await nft.mint(owner.address, 1, "uri1");
    await expect(nft.mint(owner.address, 1, "uri2"))
      .to.be.revertedWith("Token already minted");
  });

  it("reverts beyond max supply", async function () {
    await nft.mint(owner.address, 1, "uri1");
    await nft.mint(owner.address, 2, "uri2");
    await expect(nft.mint(owner.address, 3, "uri3"))
      .to.be.revertedWith("Max supply reached");
  });

  it("reverts unauthorized transfer", async function () {
    await nft.mint(owner.address, 1, "uri");
    await expect(
      nft.connect(addr1).transferFrom(owner.address, addr1.address, 1)
    ).to.be.revertedWith("Not authorized to transfer");
  });

  it("reverts getApproved for non-existent token", async function () {
    await expect(nft.getApproved(999)).to.be.revertedWith("Token does not exist");
  });

  it("reverts tokenURI for non-existent token", async function () {
    await expect(nft.tokenURI(999)).to.be.revertedWith("Token does not exist");
  });

  it("reverts mint when paused, succeeds after unpause", async function () {
    await nft.pause();
    await expect(nft.mint(owner.address, 1, "uri"))
      .to.be.revertedWith("Minting is paused");

    await nft.unpause();
    await expect(nft.mint(owner.address, 1, "uri"))
      .to.emit(nft, "Transfer")
      .withArgs("0x0000000000000000000000000000000000000000", owner.address, 1);
  });
});
