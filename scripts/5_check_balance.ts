import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";

// --- CẤU HÌNH ---
const NETWORK = Network.TESTNET;

// 1. Địa chỉ ví người dùng cần check balance
const TARGET_ADDRESS = "0x7760124c674b206ab4da9232954254955a01d823aedb27727bebf78479225063";

// 2. Địa chỉ Token trực tiếp (Asset Metadata Address)
// Bạn copy địa chỉ này từ Log của lần chạy trước hoặc từ Explorer
const METADATA_ADDRESS = "0x88ed75d06d6ad90173100c0e9997875bdfa904cea055aebb49b45bb00c9a75d9";

async function main() {
  const config = new AptosConfig({ network: NETWORK });
  const aptos = new Aptos(config);

  console.log(`--- Đang kiểm tra số dư Token tại địa chỉ: ---`);
  console.log(METADATA_ADDRESS);

  try {
    // BƯỚC 1: Gọi View Function để lấy số dư
    const balanceResult = await aptos.view({
      payload: {
        function: "0x1::primary_fungible_store::balance",

        // QUAN TRỌNG: Vẫn phải giữ dòng này thì mới không bị lỗi "Expected 1 type argument"
        typeArguments: ["0x1::fungible_asset::Metadata"],

        functionArguments: [
          TARGET_ADDRESS, // Chủ ví
          METADATA_ADDRESS, // Địa chỉ Token (truyền thẳng)
        ],
      },
    });

    const rawBalance = balanceResult[0];

    // Lưu ý: Đảm bảo Decimals đúng với cấu hình trong Smart Contract (6)
    const decimals = 6;
    const formattedBalance = Number(rawBalance) / Math.pow(10, decimals);

    console.log(`\nNgười dùng: ${TARGET_ADDRESS}`);
    console.log(`Số dư Raw : ${rawBalance}`);
    console.log(`Số dư Thực: ${formattedBalance}`); // Token Symbol là ANANTA
  } catch (error) {
    console.error("Lỗi khi kiểm tra số dư:", error);
  }
}

main();
