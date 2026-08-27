import { useState } from 'react';
import { Bell, Send } from 'lucide-react';
import { supabase } from '../lib/supabase';

export default function NotificationsPage() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [targetUsers, setTargetUsers] = useState<'all' | 'specific' | 'level'>('all');
  const [sending, setSending] = useState(false);

  const handleSend = async () => {
    if (!title.trim() || !body.trim()) return alert('Title and body required');
    setSending(true);
    const { error } = await supabase.from('notifications').insert({
      title: title.trim(),
      body: body.trim(),
      target: targetUsers,
    });
    setSending(false);
    if (error) return alert('Error: ' + error.message);
    alert('Notification sent successfully!');
    setTitle('');
    setBody('');
  };

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h2 className="text-white text-lg font-semibold">Push Notifications</h2>
        <p className="text-slate-500 text-xs mt-0.5">Send notifications to app users</p>
      </div>
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Target Audience</label>
          <div className="flex gap-2">
            {(['all', 'specific', 'level'] as const).map(t => (
              <button key={t} onClick={() => setTargetUsers(t)} className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-colors ${targetUsers === t ? 'bg-indigo-600 text-white' : 'bg-[#161618] text-slate-400 border border-white/10'}`}>
                {t === 'all' ? 'All Users' : t === 'specific' ? 'Specific Users' : 'By Level'}
              </button>
            ))}
          </div>
        </div>
        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Title</label>
          <input type="text" value={title} onChange={e => setTitle(e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white" placeholder="Notification title" />
        </div>
        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Body</label>
          <textarea value={body} onChange={e => setBody(e.target.value)} rows={4} className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white resize-none" placeholder="Notification body text" />
        </div>
        <button onClick={handleSend} disabled={sending} className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-xs text-white font-semibold rounded-lg flex items-center gap-1.5"><Send className="w-3.5 h-3.5" /> {sending ? 'Sending...' : 'Send Notification'}</button>
      </div>
    </div>
  );
}
