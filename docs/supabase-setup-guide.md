# Supabase 搭子同步 —— 手把手配置指引

这份写给"完全没接触过 Supabase"的人。作用:在网上免费建一个小数据库,
当两个人手机之间的中转站——让"我今天打卡了没"这个是/否能传给对方。
全程不写代码,主要是点鼠标 + 复制粘贴一次。

对应的数据库脚本在 `app/supabase/schema.sql`。

---

## 第一步:注册并新建项目

1. 浏览器打开 **supabase.com**,右上角点 **Sign in / Start your project**。
2. 用 GitHub 账号(`bambi2008`)或邮箱登录。
3. 点绿色的 **New project**(新建项目)。
4. 填几样:
   - **Name**:随便填,比如 `pocklume`。
   - **Database Password**:点旁边 **Generate** 自动生成,复制存到自己的
     备忘录(以后基本用不到,但存着别丢)。
   - **Region**:选离用户近的,美国用户选 `West US` / `East US`。
   - Plan 保持默认 **Free**。
5. 点 **Create new project**,等 **1–2 分钟**让它把数据库开好。

## 第二步:运行数据库代码(建表)

1. 左边竖排图标找 **SQL Editor**(图标像 `</>`)。点它。
2. 点 **New query**,出现一个空白大输入框。
3. 新开标签页打开:
   **https://github.com/bambi2008/abacus/blob/master/app/supabase/schema.sql**
4. 页面右上角小按钮里点**复制图标**("Copy raw file"),整段代码复制好。
5. 回到 Supabase 空白框里**粘贴**(Ctrl+V)。
6. 点右下角绿色 **Run**(或 Ctrl+Enter)。
7. 下面出现 **Success. No rows returned** 就成功了。报红字错误就截图求助。

## 第三步:打开"匿名登录"

不开这个,搭子功能连不上。

1. 左边竖排找 **Authentication**。点它。
2. 里面找 **Sign In / Providers**(或叫 Providers / Configuration)。
3. 找到 **Anonymous** 这一项,或一个 **Allow anonymous sign-ins** 的开关。
4. **打开**(开关变绿/变蓝),有 **Save** 就点保存。
5. 找不到就截图求助。

## 第四步:拿两把"钥匙"(最关键,别拿错)

1. 左边竖排最下面找 **Project Settings**(齿轮 ⚙️)。
2. 点 **API**(或 API Keys）。
3. 复制两样,存到备忘录:
   - **Project URL** —— 像 `https://xxxxxxxx.supabase.co`。
   - **anon public** 那个 key —— 一长串字母数字(新版可能叫 **Publishable key**)。

> ⚠️ **安全红线**:同页还有 **service_role / secret** 密钥。
> **绝对不能用、不能给人、不能放进 App**——那是管理员钥匙,泄露了别人能删
> 你整个数据库。你只要 **anon / public / publishable** 那一个。
> 记住:**要 "anon/public",不要 "service_role/secret"。**

## 第五步:这两把钥匙怎么用

这两个值(URL + anon key)不是填进 App 界面,而是在**最后打包 App 那一刻**
塞进去的。命令长这样(先了解,不用现在做):

```
flutter build ipa --dart-define=SUPABASE_URL=你的URL --dart-define=SUPABASE_ANON_KEY=你的key
```

具体在哪填取决于你用什么打包(Windows 做 iOS 包要么用 Mac、要么用 Codemagic
云打包)。**决定打包方式后,把两把钥匙准备好,告诉打包方式,就能拿到能照抄的
完整命令/配置。** 不加这两个 dart-define,搭子功能会自动退回本地占位状态
(App 不会崩,只是不同步)。

## 第六步:上架前用两台手机实测

包装进 TestFlight 后:一台点"邀请"生成邀请码,另一台输码加入,各自记一笔,
看两边是否都显示对方打卡。能同步就成。

---

**现在只需做第一到第四步**(建项目、跑代码、开匿名登录、拿两把钥匙),全在
网页上点鼠标。第五步的打包命令到那一步再说。
