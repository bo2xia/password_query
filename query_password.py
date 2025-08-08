def load_accounts(file_path):
    accounts = {}
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            for line in file:
                # 假设文本文件每行格式为：账号:密码
                if ':' in line:
                    username, password = line.strip().split(':', 1)
                    accounts[username] = password
        return accounts
    except FileNotFoundError:
        print("错误：找不到账号文件！")
        return {}
    except Exception as e:
        print(f"读取文件时出错：{e}")
        return {}

def query_password(file_path):
    # 加载账号密码
    accounts = load_accounts(file_path)
    
    if not accounts:
        print("无法加载账号数据，程序退出。")
        return
    
    # 获取用户输入
    username = input("请输入账号: ")
    
    # 查询密码
    if username in accounts:
        print(f"账号 {username} 的密码是: {accounts[username]}")
    else:
        print("账号不存在，请检查输入！")

# 运行程序
if __name__ == "__main__":
    print("欢迎使用账号密码查询系统")
    # 假设账号密码存储在 accounts.txt 文件中
    file_path = "accounts.txt"
    
    while True:
        query_password(file_path)
        # 询问是否继续查询
        choice = input("是否继续查询？(y/n): ")
        if choice.lower() != 'y':
            print("程序退出")
            break
