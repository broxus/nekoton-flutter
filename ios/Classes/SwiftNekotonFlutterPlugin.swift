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

        free_native_result(nil);

        get_accounts_storage(0, nil);

        get_accounts(0, nil);

        add_account(0, nil, nil, nil, nil, 0);

        rename_account(0, nil, nil, nil);

        remove_account(0, nil, nil);

        add_token_wallet(0, nil, nil, nil, nil);

        remove_token_wallet(0, nil, nil, nil, nil);

        clear_accounts_storage(0, nil);

        free_accounts_storage(0, nil);

        generic_contract_subscribe(0, 0, nil, nil);

        get_generic_contract_address(0, nil);

        get_generic_contract_contract_state(0, nil);

        get_generic_contract_pending_transactions(0, nil);

        get_generic_contract_polling_method(0, nil);

        generic_contract_send(0, nil, nil, nil, nil);

        generic_contract_refresh(0, nil);

        generic_contract_handle_block(0, nil, nil, nil);

        generic_contract_preload_transactions(0, nil, nil);

        generic_contract_estimate_fees(0, nil, nil);

        generic_contract_execute_transaction_locally(0, nil, nil, nil, nil, nil);

        free_generic_contract(0, nil);

        get_keystore(0, nil);

        get_entries(0, nil);

        add_key(0, nil, nil);

        update_key(0, nil, nil);

        export_key(0, nil, nil);

        check_key_password(0, nil, nil);

        remove_key(0, nil, nil);

        clear_keystore(0, nil);

        free_keystore(0, nil);

        token_wallet_subscribe(0, 0, nil, nil, nil);

        get_token_wallet_owner(0, nil);

        get_token_wallet_address(0, nil);

        get_token_wallet_symbol(0, nil);

        get_token_wallet_version(0, nil);

        get_token_wallet_balance(0, nil);

        get_token_wallet_contract_state(0, nil);

        token_wallet_prepare_deploy(0, nil, nil, nil, nil);

        token_wallet_prepare_transfer(0, nil, nil, nil, nil, nil, nil, 0);

        token_wallet_refresh(0, nil);

        token_wallet_preload_transactions(0, nil, nil);

        token_wallet_handle_block(0, nil, nil, nil);

        free_token_wallet(0, nil);

        ton_wallet_subscribe(0, 0, nil, 0, nil, nil);

        ton_wallet_subscribe_by_address(0, 0, nil, nil);

        ton_wallet_subscribe_by_existing(0, 0, nil, nil);

        find_existing_wallets(0, nil, nil, 0);

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

        ton_wallet_prepare_transfer(0, nil, nil, nil, nil, 0, nil, 0);

        ton_wallet_prepare_confirm_transaction(0, nil, nil, 0, nil);

        prepare_add_ordinary_stake(0, nil, nil, nil, nil, 0, 0);

        prepare_withdraw_part(0, nil, nil, nil, nil, 0, 0);

        ton_wallet_estimate_fees(0, nil, nil);

        ton_wallet_send(0, nil, nil, nil, nil);

        ton_wallet_refresh(0, nil);

        ton_wallet_preload_transactions(0, nil, nil);

        ton_wallet_handle_block(0, nil, nil, nil);

        free_ton_wallet(0, nil);

        generate_key(nil);

        get_hints(nil);

        derive_from_phrase(nil, nil);

        get_participant_info(0, nil, nil, nil);

        get_depool_info(0, nil, nil);

        get_adnl_connection(0, nil);

        free_adnl_connection(0, nil);

        get_gql_connection(0);

        free_gql_connection(0, nil);

        resolve_gql_request(nil, 0, nil);

        get_storage(0);

        free_storage(0, nil);

        resolve_storage_request(nil, 0, nil);

        pack_std_smc_addr(0, nil, 0);

        unpack_std_smc_addr(nil, 0);

        validate_address(nil);

        repack_address(nil);

        parse_message_body_data(nil);

        run_local(nil, nil, nil, nil, nil, nil);

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

        get_full_account_state(0, nil, nil);

        get_transactions(0, nil, nil, nil, 0);

        get_adnl_transport(0, nil);

        free_adnl_transport(0, nil);

        get_gql_transport(0, nil);

        free_gql_transport(0, nil);

        get_latest_block_id(0, nil, nil);

        wait_for_next_block_id(0, nil, nil, nil);
    }
}
