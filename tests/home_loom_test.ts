import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create a new space with category",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('home-loom', 'create-space', [
        types.utf8("Living Room"),
        types.utf8("Main living space organization"),
        types.utf8("common-areas")
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
    assertEquals(space['category'], "common-areas");
  },
});

// [Rest of the test cases remain the same with additional tests for new features]
