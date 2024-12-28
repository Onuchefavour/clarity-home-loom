import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create a new space",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('home-loom', 'create-space', [
        types.utf8("Living Room"),
        types.utf8("Main living space organization")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    let getSpace = chain.mineBlock([
      Tx.contractCall('home-loom', 'get-space', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    const space = getSpace.receipts[0].result.expectOk().expectSome();
    assertEquals(space['owner'], deployer.address);
    assertEquals(space['name'], "Living Room");
  },
});

Clarinet.test({
  name: "Can add and like tips",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('home-loom', 'add-tip', [
        types.uint(1),
        types.utf8("Use vertical space for storage")
      ], user1.address),
      Tx.contractCall('home-loom', 'like-tip', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk();
    
    let getTip = chain.mineBlock([
      Tx.contractCall('home-loom', 'get-tip', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    const tip = getTip.receipts[0].result.expectOk().expectSome();
    assertEquals(tip['author'], user1.address);
    assertEquals(tip['likes'], 1);
  },
});

Clarinet.test({
  name: "Can update progress",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('home-loom', 'create-space', [
        types.utf8("Kitchen"),
        types.utf8("Kitchen organization")
      ], deployer.address),
      Tx.contractCall('home-loom', 'update-progress', [
        types.uint(1),
        types.uint(50)
      ], deployer.address)
    ]);
    
    block.receipts[1].result.expectOk();
    
    let getSpace = chain.mineBlock([
      Tx.contractCall('home-loom', 'get-space', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    const space = getSpace.receipts[0].result.expectOk().expectSome();
    assertEquals(space['progress'], 50);
  },
});