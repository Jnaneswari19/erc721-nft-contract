const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NftCollection", function () {
  let NftCollection, nft, owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    NftCollection = await ethers.getContractFactory("NftCollection");
    nft = await NftCollection.deploy("MyNFT", "MNFT", 10);
  });

  it("Should mint a token and emit Transfer event", async function () {
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

    await expect(nft.mint(owner.address, 1, "https://example.com/1.json"))
      .to.emit(nft, "Transfer")
      .withArgs(ZERO_ADDRESS, owner.address, 1);

    expect(await nft.ownerOf(1)).to.equal(owner.address);
    expect(await nft.tokenURI(1)).to.equal("https://example.com/1.json");
  });

  it("Should approve another address and emit Approval event", async function () {
    await nft.mint(owner.address, 2, "https://example.com/2.json");

    await expect(nft.approve(addr1.address, 2))
      .to.emit(nft, "Approval")
      .withArgs(owner.address, addr1.address, 2);

    expect(await nft.getApproved(2)).to.equal(addr1.address);
  });

  it("Should set operator approval and emit ApprovalForAll event", async function () {
    await expect(nft.setApprovalForAll(addr1.address, true))
      .to.emit(nft, "ApprovalForAll")
      .withArgs(owner.address, addr1.address, true);

    expect(await nft.isApprovedForAll(owner.address, addr1.address)).to.equal(true);
  });

  it("Should transfer token and emit Transfer event", async function () {
    await nft.mint(owner.address, 3, "https://example.com/3.json");
    await nft.approve(addr1.address, 3);

    await expect(nft.connect(addr1).transferFrom(owner.address, addr2.address, 3))
      .to.emit(nft, "Transfer")
      .withArgs(owner.address, addr2.address, 3);

    expect(await nft.ownerOf(3)).to.equal(addr2.address);
  });
});
