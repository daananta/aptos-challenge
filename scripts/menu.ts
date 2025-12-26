import inquirer from "inquirer";
import { execSync } from "child_process";

const main = async () => {
  console.clear();
  console.log("\n🎲 --- APTOS LOTTERY MANAGER --- 🎲\n");

  const answer = await inquirer.prompt([
    {
      type: "list",
      name: "action",
      message: "Bạn muốn làm gì?",
      choices: [
        { name: "🚀 1. Khởi tạo Token & Mint (Init & Mint)", value: "1_init_and_mint.ts" },
        { name: "🎟️  2. Mua vé số (Buy Ticket)", value: "2_buy_ticket.ts" },
        { name: "🏆 3. Chọn người trúng (Pick Winner)", value: "3_pick_winner.ts" },
        { name: "💰 4. Mint Token cho User", value: "4_mint_token_to_user.ts" },
        // 👇 THÊM LỰA CHỌN MỚI
        { name: "🔍 5. Kiểm tra số dư (Check Balance)", value: "5_check_balance.ts" },
        new inquirer.Separator(),
        { name: "❌ Thoát", value: "exit" },
      ],
    },
  ]);

  if (answer.action === "exit") {
    console.log("Tạm biệt!");
    process.exit(0);
  }

  // Biến lưu các tham số sẽ truyền vào command
  let args = "";

  // --- XỬ LÝ RIÊNG CHO TỪNG FILE ---

  // 1. Logic cho Mua vé
  if (answer.action === "2_buy_ticket.ts") {
    const ticketAnswer = await inquirer.prompt([
      {
        type: "input",
        name: "amount",
        message: "Bạn muốn mua bao nhiêu vé?",
        default: "1",
        validate: (input) => {
          const num = parseInt(input);
          if (isNaN(num) || num <= 0) return "Vui lòng nhập số dương!";
          return true;
        },
      },
    ]);
    args = ` ${ticketAnswer.amount}`;
  }

  // 2. Logic cho Mint Token
  else if (answer.action === "4_mint_token_to_user.ts") {
    const mintAnswers = await inquirer.prompt([
      {
        type: "input",
        name: "address",
        message: "Nhập địa chỉ ví nhận tiền:",
        validate: (input) => {
          if (!input.startsWith("0x") || input.length < 60) {
            return "Địa chỉ ví không hợp lệ (Phải bắt đầu bằng 0x...)";
          }
          return true;
        },
      },
      {
        type: "input",
        name: "amount",
        message: "Nhập số lượng Token muốn mint:",
        default: "100000000",
        validate: (input) => {
          if (isNaN(parseInt(input))) return "Vui lòng nhập số!";
          return true;
        },
      },
    ]);
    args = ` ${mintAnswers.address} ${mintAnswers.amount}`;
  }

  // 👇 3. LOGIC MỚI CHO CHECK BALANCE (File số 5)
  else if (answer.action === "5_check_balance.ts") {
    const balanceAnswer = await inquirer.prompt([
      {
        type: "input",
        name: "address",
        message: "Nhập địa chỉ ví cần xem (Nhấn Enter để check ví Admin):",
        // Không bắt buộc nhập (validate) để cho phép user nhấn Enter lấy mặc định
      },
    ]);

    // Nếu người dùng có nhập gì đó (khác rỗng), thì gán vào args
    if (balanceAnswer.address.trim() !== "") {
      args = ` ${balanceAnswer.address.trim()}`;
    }
    // Nếu để trống, args vẫn là chuỗi rỗng "", file số 5 sẽ tự lấy mặc định Admin.
  }

  // --- CHẠY LỆNH ---
  try {
    console.log(`\n⏳ Đang chạy: ${answer.action}...\n`);

    // Dùng pnpm ts-node thay vì npx cho đồng bộ với các lệnh bạn hay dùng
    execSync(`pnpm ts-node scripts/${answer.action}${args}`, { stdio: "inherit" });

    console.log("\n✅ Lệnh đã chạy xong!");
  } catch (error) {
    console.log("\n❌ Script dừng hoặc có lỗi.");
  }
};

main();
