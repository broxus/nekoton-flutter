import Flutter
import UIKit

public class SwiftNekotonFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with _: FlutterPluginRegistrar) {}

    public func handle(_: FlutterMethodCall, result: @escaping FlutterResult) {
        result(nil)
    }

    public func dummyMethodToEnforceBundling() {
        // This will never be executed

        store_post_cobject(nil);

        free_cstring(nil);

        free_execution_result(nil);

        clone_unsigned_message_ptr(nil);

        free_unsigned_message_ptr(nil);

        create_accounts_storage(0, nil);

        clone_accounts_storage_ptr(nil);

        free_accounts_storage_ptr(nil);

        get_accounts(0, nil);

        add_account(0, nil, nil, nil, nil, 0);

        rename_account(0, nil, nil, nil);

        remove_account(0, nil, nil);

        add_token_wallet(0, nil, nil, nil, nil);

        remove_token_wallet(0, nil, nil, nil, nil);

        clear_accounts_storage(0, nil);

        generic_contract_subscribe(0, 0, 0, 0, 0, nil, 0, nil);

        clone_generic_contract_ptr(nil);

        free_generic_contract_ptr(nil);

        get_generic_contract_address(0, nil);

        get_generic_contract_contract_state(0, nil);

        get_generic_contract_pending_transactions(0, nil);

        get_generic_contract_polling_method(0, nil);

        generic_contract_estimate_fees(0, nil, nil);

        generic_contract_send(0, nil, nil, nil, nil);

        generic_contract_execute_transaction_locally(0, nil, nil, nil, nil, nil);

        generic_contract_refresh(0, nil);

        generic_contract_preload_transactions(0, nil, nil);

        generic_contract_handle_block(0, nil, nil, 0, nil);

        create_keystore(0, nil);

        clone_keystore_ptr(nil);

        free_keystore_ptr(nil);

        get_entries(0, nil);

        add_key(0, nil, nil);

        update_key(0, nil, nil);

        export_key(0, nil, nil);

        check_key_password(0, nil, nil);

        remove_key(0, nil, nil);

        clear_keystore(0, nil);

        token_wallet_subscribe(0, 0, 0, nil, 0, nil, nil);

        clone_token_wallet_ptr(nil);

        free_token_wallet_ptr(nil);

        get_token_wallet_owner(0, nil);

        get_token_wallet_address(0, nil);

        get_token_wallet_symbol(0, nil);

        get_token_wallet_version(0, nil);

        get_token_wallet_balance(0, nil);

        get_token_wallet_contract_state(0, nil);

        token_wallet_prepare_transfer(0, nil, nil, nil, 0, nil);

        token_wallet_refresh(0, nil);

        token_wallet_preload_transactions(0, nil, nil);

        ton_wallet_subscribe(0, 0, 0, 0, 0, nil, 0, 0, nil, nil);

        ton_wallet_subscribe_by_address(0, 0, 0, 0, 0, nil, 0, nil);

        ton_wallet_subscribe_by_existing(0, 0, 0, 0, 0, nil, 0, nil);

        clone_ton_wallet_ptr(nil);

        free_ton_wallet_ptr(nil);

        find_existing_wallets(0, nil, 0, nil, 0);

        get_ton_wallet_workchain(0, nil);

        get_ton_wallet_address(0, nil);

        get_ton_wallet_public_key(0, nil);

        get_ton_wallet_wallet_type(0, nil);

        get_ton_wallet_contract_state(0, nil);

        get_ton_wallet_pending_transactions(0, nil);

        get_ton_wallet_polling_method(0, nil);

        get_ton_wallet_details(0, nil);

        get_ton_wallet_unconfirmed_transactions(0, nil);

        get_ton_wallet_custodians(0, nil);

        ton_wallet_prepare_deploy(0, nil, nil);

        ton_wallet_prepare_deploy_with_multiple_owners(0, nil, nil, nil, 0);

        ton_wallet_prepare_transfer(0, nil, nil, 0, nil, nil, nil, nil, nil);

        ton_wallet_prepare_confirm_transaction(0, nil, nil, 0, nil, nil, nil);

        ton_wallet_estimate_fees(0, nil, nil);

        ton_wallet_send(0, nil, nil, nil, nil);

        ton_wallet_refresh(0, nil);

        ton_wallet_preload_transactions(0, nil, nil);

        ton_wallet_handle_block(0, nil, nil, 0, nil);

        generate_key(nil);

        get_hints(nil);

        derive_from_phrase(nil, nil);

        create_storage(nil);

        clone_storage_ptr(nil);

        free_storage_ptr(nil);

        get_full_account_state(0, nil, 0, nil);

        get_transactions(0, nil, 0, nil, nil, 0);

        create_gql_transport(nil);

        clone_gql_transport_ptr(nil);

        free_gql_transport_ptr(nil);

        get_latest_block_id(0, nil, nil);

        wait_for_next_block_id(0, nil, nil, nil, 0);

        create_jrpc_transport(nil);

        clone_jrpc_transport_ptr(nil);

        free_jrpc_transport_ptr(nil);

        pack_std_smc_addr(0, nil, 0);

        unpack_std_smc_addr(nil, 0);

        validate_address(nil);

        repack_address(nil);

        run_local(nil, nil, nil, nil);

        get_expected_address(nil, nil, 0, nil, nil);

        pack_into_cell(nil, nil);

        unpack_from_cell(nil, nil, 0);

        extract_public_key(nil);

        code_to_tvc(nil);

        split_tvc(nil);

        encode_internal_input(nil, nil, nil);

        decode_input(nil, nil, nil, 0);

        decode_output(nil, nil, nil);

        decode_event(nil, nil, nil);

        decode_transaction(nil, nil, nil);

        decode_transaction_events(nil, nil);

        parse_known_payload(nil);

        create_external_message(nil, nil, nil, nil, nil, nil, 0);
    }
}
