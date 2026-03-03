import { QUARTERLY_LIMIT_THRESHOLD } from '../constants';

// Define shapes for the analysis payload locally to avoid dependency issues with computed types
interface StoreAnalysisData {
  companyName: string;
  quarterIncome: number;
  invoicesReceived: number;
  gap: number;
  taxType: string;
  historicalSuppliers: string[];
}

interface SupplierAnalysisData {
  name: string;
  remainingQuota: number;
  status: string;
  type: string;
}

const API_ENDPOINT = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
const API_KEY = '5564d7ea-a6df-41a0-8d86-f89f52cabbf7';
const MODEL = 'doubao-1-5-pro-32k-250115';

export const analyzeTaxOptimization = async (stores: StoreAnalysisData[], suppliers: SupplierAnalysisData[]) => {
  try {
    const contextData = JSON.stringify({
      taxRule: `个体工商户每季度有 ${QUARTERLY_LIMIT_THRESHOLD} 元的免税额度。`,
      stores: stores.map(s => ({
        name: s.companyName,
        income: s.quarterIncome,
        currentInvoices: s.invoicesReceived,
        gap: s.gap,
        taxType: s.taxType,
        historicalSuppliers: s.historicalSuppliers
      })),
      factories: suppliers.map(s => ({
        name: s.name,
        remainingQuota: s.remainingQuota,
        status: s.status,
        type: s.type
      }))
    });

    const prompt = `
      扮演电商集团的资深税务优化专家。
      分析以下JSON数据，代表我们的店铺公司和工厂（个体户）情况。
      
      目标：最大化利用个体户的免税额度，同时减少店铺公司的发票缺口。
      
      分配原则：
      1. 优先使用历史上为该店铺开票的供应商继续开票
      2. 一般纳税人店铺优先使用一般纳税人供应商开票
      3. 最大化利用供应商的剩余额度
      4. 避免供应商超过季度限额
      
      数据：
      ${contextData}

      请提供一份简明扼要、可执行的中文Markdown格式计划：
      1. 识别哪个店铺缺票最严重。
      2. 识别哪些工厂还有大量剩余额度。
      3. 给出具体的配对建议，包括供应商名称、店铺名称和开票金额，遵循分配原则。
      4. 警告哪些工厂已接近28万红线。
      5. 提供一个结构化的JSON格式的分配方案，用于自动处理。
    `;

    const response = await fetch(API_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`
      },
      body: JSON.stringify({
        model: MODEL,
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 2000
      })
    });

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    return data.choices[0].message.content;
  } catch (error) {
    console.error("Doubao Analysis Error:", error);
    return "无法生成分析结果，请检查API配置。";
  }
};

export const createChatSession = () => {
  // 由于更换为Doubao API，这里返回一个模拟的聊天会话对象
  // 实际使用时需要根据Doubao API的聊天接口进行调整
  return {
    sendMessage: async (message: string) => {
      try {
        const response = await fetch(API_ENDPOINT, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${API_KEY}`
          },
          body: JSON.stringify({
            model: MODEL,
            messages: [
              {
                role: 'system',
                content: '你是一个专业的中国电商税务助手。你了解关于“个体工商户”的税务法规，特别是28万元的季度免税限额。帮助用户管理他们的发票和工厂（供应商）。请始终用中文回答。'
              },
              {
                role: 'user',
                content: message
              }
            ],
            temperature: 0.7,
            max_tokens: 1000
          })
        });

        if (!response.ok) {
          throw new Error(`API request failed: ${response.status} ${response.statusText}`);
        }

        const data = await response.json();
        return {
          text: data.choices[0].message.content
        };
      } catch (error) {
        console.error("Doubao Chat Error:", error);
        return {
          text: "无法生成回复，请检查API配置。"
        };
      }
    }
  };
};