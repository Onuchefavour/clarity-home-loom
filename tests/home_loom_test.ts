import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Contract pause functionality works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user = accounts.get('wallet_1')!;
    
    // Test pausing
    let block = chain.mineBlock([
      Tx.contractCall('home-loom', 'set-paused', [
        types.bool(true)
      ], deployer.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test creating space while paused
    block = chain.mineBlock([
      Tx.contractCall('home-loom', 'create-space', [
        types.utf8("Living Room"),
        types.utf8("Description"),
        types.utf8("category")
      ], user.address)
    ]);
    block.receipts[0].result.expectErr().expectUint(107);
  }
});

// [Previous test cases remain with additional tests for new features]
