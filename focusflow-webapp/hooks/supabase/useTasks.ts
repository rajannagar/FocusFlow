'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { createClient } from '@/lib/supabase/client';
import type { Task } from '@/types';
import { useTasksStore } from '@/stores/useTasksStore';
import { useEffect } from 'react';

function transformTask(row: any): Task {
  return {
    id: row.id,
    sortIndex: row.sort_index || 0,
    title: row.title,
    notes: row.notes,
    reminderDate: row.reminder_date,
    repeatRule: row.repeat_rule || 'none',
    customWeekdays: row.custom_weekdays || [],
    durationMinutes: row.duration_minutes || 0,
    convertToPreset: row.convert_to_preset || false,
    presetCreated: row.preset_created || false,
    excludedDayKeys: row.excluded_day_keys || [],
    createdAt: row.created_at,
  };
}

export function useTasks(userId?: string) {
  const supabase = createClient();
  const { setTasks, setLoading } = useTasksStore();
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['tasks', userId],
    queryFn: async () => {
      if (!userId) return [];
      
      setLoading(true);
      const { data, error } = await supabase
        .from('tasks')
        .select('*')
        .eq('user_id', userId)
        .order('sort_index', { ascending: true });

      if (error) throw error;
      
      const tasks = (data || []).map(transformTask);
      setTasks(tasks);
      setLoading(false);
      return tasks;
    },
    enabled: !!userId,
    staleTime: 1000 * 30,
  });

  useEffect(() => {
    if (query.data) {
      setTasks(query.data);
    }
  }, [query.data, setTasks]);

  const addTask = useMutation({
    mutationFn: async (task: Omit<Task, 'id' | 'createdAt'>) => {
      if (!userId) throw new Error('User ID is required');
      
      const { data, error } = await supabase
        .from('tasks')
        .insert({
          user_id: userId,
          sort_index: task.sortIndex,
          title: task.title,
          notes: task.notes,
          reminder_date: task.reminderDate,
          repeat_rule: task.repeatRule,
          custom_weekdays: task.customWeekdays,
          duration_minutes: task.durationMinutes,
          convert_to_preset: task.convertToPreset,
          preset_created: task.presetCreated,
          excluded_day_keys: task.excludedDayKeys,
        })
        .select()
        .single();

      if (error) throw error;
      return transformTask(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks', userId] });
    },
  });

  const updateTask = useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<Task> }) => {
      if (!userId) throw new Error('User ID is required');
      
      const updateData: any = {};
      if (updates.title !== undefined) updateData.title = updates.title;
      if (updates.notes !== undefined) updateData.notes = updates.notes;
      if (updates.reminderDate !== undefined) updateData.reminder_date = updates.reminderDate;
      if (updates.repeatRule !== undefined) updateData.repeat_rule = updates.repeatRule;
      if (updates.customWeekdays !== undefined) updateData.custom_weekdays = updates.customWeekdays;
      if (updates.durationMinutes !== undefined) updateData.duration_minutes = updates.durationMinutes;
      if (updates.convertToPreset !== undefined) updateData.convert_to_preset = updates.convertToPreset;
      if (updates.presetCreated !== undefined) updateData.preset_created = updates.presetCreated;
      if (updates.excludedDayKeys !== undefined) updateData.excluded_day_keys = updates.excludedDayKeys;
      if (updates.sortIndex !== undefined) updateData.sort_index = updates.sortIndex;

      const { data, error } = await supabase
        .from('tasks')
        .update(updateData)
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

      if (error) throw error;
      return transformTask(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks', userId] });
    },
  });

  const deleteTask = useMutation({
    mutationFn: async (id: string) => {
      if (!userId) throw new Error('User ID is required');
      
      const { error } = await supabase
        .from('tasks')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);

      if (error) throw error;
      return id;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks', userId] });
    },
  });

  return {
    tasks: query.data || [],
    isLoading: query.isLoading,
    error: query.error,
    addTask: addTask.mutateAsync,
    updateTask: updateTask.mutateAsync,
    deleteTask: deleteTask.mutateAsync,
    isAdding: addTask.isPending,
    isUpdating: updateTask.isPending,
    isDeleting: deleteTask.isPending,
  };
}

