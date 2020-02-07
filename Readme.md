# Smart Contract Budget Auditing
    
This is a demo Smart Contract that controls the release of funds according to a specific expenses breakdown (i.e. a budget). The idea is to register expenses keywords and then, ask the Smart Contract to approve or not a transaction that is recognized by that keyword.

This Smart Contract **IS NOT** transfering any funds, rather it approves/reject transactions (transaction clearing) following these rules:
- The transaction category (__specified by a keyword__) belongs to a predifined list
- The transaction can be repeated or not
- The approved upper limit of that transaction category is reached or not

This Smart Contract was implememted as part of the **Give n' Trust** idea that won the 2nd prize at the Business Competition FintechChallenge 2017 organized by AplhaBank (Greece). More info: [https://youtu.be/YctmGpFCUho?t=6667](https://youtu.be/YctmGpFCUho?t=6667).